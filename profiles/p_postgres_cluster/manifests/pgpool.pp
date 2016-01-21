class p_postgres_cluster::pgpool (
  $pcp_root_pass
){
  $vip=$p_postgres_cluster::vip
  $pgpool_cluster_pw=$p_postgres_cluster::cluster_pw
  $pgpool_service_interface=$p_postgres_cluster::service_interface
  $pgpool_trusted_servers=$p_postgres_cluster::trusted_servers
  $pgpool_id=$p_postgres_cluster::id
  $pgpool_port=$p_postgres_cluster::pgpool_port

  #TODO: seperate heartbeat network
  ensure_packages("iputils-arping", {notify => Service["pgpool"]})
  # install the package and the service
  class { '::pgpool': } 
  # setup our pgpool.conf
  class { '::pgpool::config::connection': 
    socket_dir => '/var/run/postgresql',
    pcp_socket_dir => '/var/run/postgresql',
    port => $pgpool_port,
    listen_addresses => "*"
  }
  class { '::pgpool::config::failover':
    failover_command => "ssh %H \"if [ %d = %P ];then touch $::postgresql::server::datadir/trigger;fi\"",
    failback_command => "ssh %h \"if [ ! -f $::postgresql::server::datadir/recovery.conf ];then echo standby_mode = \\\"on\\\" > $::postgresql::server::datadir/recovery.conf && /usr/bin/pg_ctlcluster $::postgresql::globals::globals_version main restart;fi\""
  }
  class { '::pgpool::config::healthcheck':
    health_check_period      => 5,
    health_check_timeout     => 10,
    health_check_user        => 'pgpool',
    health_check_password    => $pgpool_cluster_pw,
    health_check_max_retries => 1,
  }
  class { '::pgpool::config::loadbalance':
    load_balance_mode => 'off',
  }
  class { '::pgpool::config::logs':
    log_connections  => 'on',
    log_statement    => 'off',
    log_min_messages => 'info',
  }
  class { '::pgpool::config::masterslave':
    master_slave_mode     => 'on',
    master_slave_sub_mode => 'stream',
    sr_check_period       => 5,
    sr_check_user         => 'pgpool',
    sr_check_password     => $pgpool_cluster_pw,
    delay_threshold       => 1024000,
  }
  class { '::pgpool::config::pools':
    enable_pool_hba => 'on',
  }
  class { '::pgpool::config::replication':
    replication_mode => 'off',
  }
  class { '::pgpool::config::service':
    pid_file_name => '/var/run/postgresql/pgpool.pid',
    logdir        => '/var/log/postgresql',
  }
  class { '::pgpool::config::ssl': }

  # Configure watchdog
  file {"/usr/local/bin/ping":
    mode => "755",
    content => "#!/bin/sh
sudo /bin/ping \"\$@\"
"
  }
  file {"/etc/sudoers.d/88-pgpool-wd":
    ensure => present,
    owner => root,
    group => root,
    mode => "440",
    content => inline_template("postgres ALL= NOPASSWD: /sbin/ip a add dev $pgpool_service_interface $vip/32
postgres ALL= NOPASSWD: /sbin/ip a del dev $pgpool_service_interface $vip/32
postgres ALL= NOPASSWD: /bin/ping -q -c3 $vip
<% @pgpool_trusted_servers.each do |trusted_server| -%>
postgres ALL= NOPASSWD: /bin/ping -q -c3 <%= trusted_server %>
<% end -%>
postgres ALL= NOPASSWD: /usr/local/sbin/arping.sh
")
  }
  file {"/usr/local/sbin/arping.sh":
    mode => "755",
    content => "#!/bin/sh
/usr/bin/arping -U $vip -w1

# WSGI service needs to be restarted
/usr/sbin/service apache2 restart || true

# DNS should be restarted
/usr/sbin/service bind9 restart || true

# Proxy should be restarted
/usr/sbin/service maas-proxy start || true
"
  }
  ensure_packages("postgresql-common")
  user{"postgres":
    groups => "cansudo",
    require => Package["postgresql-common"]
  }

  $wd_heartbeat_port = 9694
  class { '::pgpool::config::watchdog': 
    use_watchdog => "on",
    trusted_servers => join($pgpool_trusted_servers,","),
    delegate_IP => $vip,
    ping_path => "/usr/local/bin",
    ifconfig_path => "/usr/bin",
    if_up_cmd => "sudo /sbin/ip a add dev $pgpool_service_interface $vip/32",
    if_down_cmd => "sudo /sbin/ip a del dev $pgpool_service_interface $vip/32",
    arping_path => "/usr/bin",
    arping_cmd => "sudo /usr/local/sbin/arping.sh",
    wd_lifecheck_method => 'heartbeat',
    wd_heartbeat_port => $wd_heartbeat_port,    
  }

  @@::pgpool::config::heartbeat { $fqdn:
    id => 0,
    destination => $ipaddress,
    port => $wd_heartbeat_port
  }
  ::Pgpool::Config::Heartbeat <<| title!=$fqdn |>>
  #::Pgpool::Config::Heartbeat <<||>>

  @@::pgpool::config::wdother { $fqdn:
    id => 0,
    hostname => $ipaddress,
    port => $pgpool_port
  }
  ::Pgpool::Config::Wdother <<| title!=$fqdn |>>
  #::Pgpool::Config::Wdother <<||>>
  
  #@@firewall { "100 allow pgpool tcp from $fqdn":
  #  dport => [9000,$pgpool_port,5432],
  #  source => $ipaddress,
  #  proto  => "tcp",
  #  action => accept,
  #  tag => ["pgpool_other"]
  #}
  #@@firewall { "100 allow pgpool udp from $fqdn":
  #  dport => 9694,
  #  source => $ipaddress,
  #  proto  => "udp",
  #  action => accept,
  #  tag => ["pgpool_other"]
  #}
  #Firewall<<| tag == "pgpool_other" |>>

  # configure our backend systems
  @@::pgpool::config::backend { $fqdn:
    id             => $pgpool_id,
    hostname       => $ipaddress,
    port           => 5432,
    data_directory => $postgresql::params::datadir,
  }
  ::Pgpool::Config::Backend <<||>>

  ::pgpool::hba { 'anyone_md5_localhost':
    type        => 'host',
    database    => 'all',
    user        => 'all',
    address     => '127.0.0.1/32',
    auth_method => 'md5',
  }

  ::pgpool::pcp {"root":
    password_hash => $pcp_root_pass
  }
}

