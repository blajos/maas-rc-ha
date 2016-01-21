class p_postgres_cluster::postgres_replication {
  $primary_fqdn=$p_postgres_cluster::primary_fqdn
  $cluster_pw=$p_postgres_cluster::cluster_pw
  $postgres_version=$p_postgres_cluster::postgres_version

  include ::postgresql::globals
  include ::postgresql::server # Set listen_addresses to "*" in hiera
  Class["::Postgresql::Globals"] -> Class["::Postgresql::Server"]

  @@postgresql::server::pg_hba_rule { "allow replication from $fqdn":
    description => "allow replication from $fqdn",
    type => 'host',
    database => 'replication',
    user => 'postgresrepl',
    address => "$ipaddress/32",
    auth_method => 'md5',
    tag => ["replication"]
  }
  Postgresql::Server::Pg_hba_rule<<| tag=="replication" |>>

  ensure_packages(["rsync"])

  file {"/usr/local/sbin/pg_initial_sync.sh":
    ensure => present,
    owner => "root",
    group => "root",
    mode => "755",
    require => Package["postgresql-server"],
    content => template("p_postgres_cluster/pg_initial_sync.sh.erb")
  }

  Postgresql_conf {
    target => "/etc/postgresql/9.3/main/postgresql.conf"
  }

  postgresql_conf {"wal_level":
    ensure => present,
    value => "hot_standby",
  }
  postgresql_conf {"max_wal_senders":
    ensure => present,
    value => "3",
  }
  postgresql_conf {"hot_standby":
    ensure => present, 
    value => "on"
  }
  postgresql_conf {"checkpoint_segments":
    ensure => present, 
    value => "16"
  }
  postgresql_conf {"wal_keep_segments":
    ensure => present,
    value => "32"
  }

  if $primary_fqdn==$fqdn {
    # We are master
    postgresql::server::role { 'postgresrepl':
      password_hash => postgresql_password('postgresrepl', $cluster_pw),
      replication => true
    }
    postgresql::server::role { 'pgpool':
      password_hash => postgresql_password('pgpool',$cluster_pw),
    }
    file {"/var/lib/postgresql/$postgres_version/main/.stamp-pg_initial_sync":
      ensure => absent
    }
  }
  else {
    # We are slaves
    exec {"/usr/local/sbin/pg_initial_sync.sh":
      creates => "/var/lib/postgresql/$postgres_version/main/.stamp-pg_initial_sync"
    }
    
    file {"/var/lib/postgresql/$postgres_version/main/recovery.done":
      ensure => absent
    }
  }
}
