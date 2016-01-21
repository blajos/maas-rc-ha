class runit {
  package { 'runit': ensure => installed } ~>

  file { "/etc/sv":
    ensure => directory,
  }
}
