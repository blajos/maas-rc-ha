define runit::service {
  include ::runit

  $instancedir = "/etc/sv/$name"
  $logdir = "$instancedir/log"

# Set up logging
  file { "$logdir":
    ensure => directory
  } ~>
  file { "/run/sv.$name.log":
    ensure => directory
  } ~>
  file { "$logdir/supervise":
    ensure => link,
    target => "/run/sv.$name.log"
  } ~>
  file { "$logdir/run":
    ensure => present,
    mode => "700",
    content => "#!/bin/sh\nexec chpst -u nobody:nogroup logger -t sv_$name\n"
  } ~>
  service { "$name/log" :
    ensure => running,
    provider => "runit",
    subscribe => File["/etc/service/$name"],
    path => "/etc/sv",
    notify => Service["$name"]
  }

# Set up basic structure
  file { "$instancedir":
    ensure => directory
  } ~>
  file { "/run/sv.$name":
    ensure => directory
  } ~>
  file { "$instancedir/supervise":
    ensure => link,
    target => "/run/sv.$name"
  } ~>
  service { "$name" :
    ensure => running,
    provider => "runit",
    path => "/etc/sv",
    subscribe => File["$instancedir/run", "/etc/service/$name"]
  }

# Register with runit
  file { "/etc/service/$name":
    ensure => link,
    target => $instancedir,
    require => File["$instancedir/supervise", "$logdir/supervise"]
  }

}

