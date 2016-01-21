class p_maas::clustercontroller {
  ensure_packages(["ipmitool"])

  File <<| title == "/root/install/maas-cluster-controller.preseed" |>> ~>
  package{"maas-cluster-controller":
    ensure => present,
    responsefile => "/root/install/maas-cluster-controller.preseed"
  }

  include apache
  apache::custom_config { "maas-cluster-http":
    source => "puppet:///modules/p_maas/maas-cluster-http.conf"
  }

  $dns_servers = hiera_array("dnsclient::nameservers")
  file { "/etc/maas/templates/dhcp/dhcpd.conf.template":
    ensure => present,
    content => template("p_maas/dhcpd.conf.template.erb"),
    owner => "root",
    group => "root",
    mode => "0644",
    require => Package["maas-cluster-controller"]
  }

  #firewall { "100 allow dhcp":
  #  dport   => ["67-69"],
  #  proto  => "udp",
  #  action => accept,
  #}
  #
  #firewall { "100 allow iscsi":
  #  dport   => ["3260"],
  #  proto  => "tcp",
  #  action => accept,
  #}
  #
  #firewall { "100 allow bootimage access over http":
  #  dport   => ["80"],
  #  proto  => "tcp",
  #  action => accept,
  #}
  #
  #firewall { "100 allow syslog":
  #  dport   => ["514"],
  #  proto  => "udp",
  #  action => accept,
  #}
  #
  #firewall { "100 allow dhcp ipv6":
  #  dport   => ["67-69"],
  #  proto  => "udp",
  #  action => accept,
  #  provider => "ip6tables",
  #}
  #
  #firewall { "100 allow iscsi ipv6":
  #  dport   => ["3260"],
  #  proto  => "tcp",
  #  action => accept,
  #  provider => "ip6tables",
  #}
  #
  #firewall { "100 allow bootimage access over http ipv6":
  #  dport   => ["80"],
  #  proto  => "tcp",
  #  action => accept,
  #  provider => "ip6tables",
  #}
  #
  #firewall { "100 allow syslog ipv6":
  #  dport   => ["514"],
  #  proto  => "udp",
  #  action => accept,
  #  provider => "ip6tables",
  #}

  # TODO: use later maas version and set up stricter rules
  # https://bugs.launchpad.net/maas/+bug/1352923
  #@@firewall { "100 allow $fqdn cluster controller registration":
  #  source => $::ipaddress,
  #  dport   => "1024-65535",
  #  proto  => "tcp",
  #  action => accept,
  #  tag => "cluster-controller-registration"
  #}

}
