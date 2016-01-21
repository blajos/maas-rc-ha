class p_postgres_cluster (
  $vip,
  $pgpool_port=9999,
  $id,
  $primary_fqdn, #FIXME: probably ip
  $cluster_pw,
  $service_interface,
  $trusted_servers,
  $postgres_version="9.3",
  $ssh_privkey,
  $ssh_pubkey
) {
  include p_postgres_cluster::postgres_replication
  include p_postgres_cluster::pgpool

  file {"/var/lib/postgresql/.ssh":
    ensure => directory,
    owner => postgres,
    group => postgres,
    require => User["postgres"]
  }~>
  ssh_authorized_key { 'postgresql user equivalence':
    user => "postgres",
    type => "ssh-rsa",
    key => $ssh_pubkey
  }
  file {"/var/lib/postgresql/.ssh/id_rsa":
    ensure => present,
    owner => postgres,
    group => postgres,
    mode => "600",
    content => $ssh_privkey
  }
}
