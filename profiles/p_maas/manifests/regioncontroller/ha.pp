class p_maas::regioncontroller::ha (
  $vip,
  $pgpool_port=9999,
  $primary_fqdn,
  $zones
) {
  class {"p_maas::regioncontroller":
    dbhost => $vip,
    dbport => $pgpool_port,
    is_primary => ( $primary_fqdn == $fqdn ),
    regioncontroller_ip => $vip
  }

# Database+vip
  class {"p_postgres_cluster":
    vip => $vip,
    pgpool_port => $pgpool_port,
    primary_fqdn => $primary_fqdn
  }

  Service["pgpool"] -> Exec["maas_syncdb"]

  ::pgpool::pool_passwd { "maas":
    password_hash => postgresql_password("maas",$::p_maas::regioncontroller::dbpassword),
  }

  ::pgpool::hba { 'maas_md5_from_vip':
    type        => 'host',
    database    => 'maasdb',
    user        => 'maas',
    address     => "$vip/32",
    auth_method => 'md5',
  }

# Bind9
  file { "/etc/default/bind9":
    owner => "root",
    group => "root",
    content => 'RESOLVCONF=no
OPTIONS="-u bind -p 5353"'
  }~>
  service { "bind9":
    ensure => running,
    enable => true
  }

  # FIXME collector
  #firewall { "100 allow maas dns access over tcp":
  #  dport   => 5353,
  #  proto  => "tcp",
  #  action => accept,
  #}
  #
  #firewall { "100 allow maas dns access over udp":
  #  dport   => 5353,
  #  proto  => "udp",
  #  action => accept,
  #}

  runit::service::basic{"named.slave":
    content => "#!/bin/sh
touch /var/cache/bind.slave/managed-keys.bind.jnl /var/cache/bind.slave/managed-keys.bind
chown bind:bind /var/cache/bind.slave/managed-keys.bind.jnl /var/cache/bind.slave/managed-keys.bind 
exec named -u bind -g -c /etc/bind/named.conf.slave 2>&1"
  }

  file {"/etc/bind/named.conf.slave":
    content => template("p_maas/named.conf.slave.erb"),
    notify => Service["named.slave"]
  }
  file {"/var/cache/bind.slave":
    ensure => directory,
    owner => "root",
    group => "bind",
    mode => "775",
    notify => Service["named.slave"]
  }

  file {"/etc/apparmor.d/usr.sbin.named":
    ensure => present,
    owner => "root",
    group => "root",
    mode => "644",
    source => "puppet:///modules/p_maas/apparmor-usr.sbin.named",
  } ~>
  service {"apparmor":
    ensure => running,
    notify => Service["named.slave"]
  }

}
