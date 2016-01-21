define runit::service::basic (
  $source = undef,
  $content = undef
) {
  runit::service { $name : }

  file { "/etc/sv/$name/run":
    mode => "700",
    source => $source,
    content => $content
  }
}
