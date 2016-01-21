class roles::maas_cluster {
  include roles::common

  include p_maas::clustercontroller
}
