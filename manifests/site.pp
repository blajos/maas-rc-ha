$role=hiera('role')

class { "roles::$role": }

file { "/root/install":
    ensure => directory
}
