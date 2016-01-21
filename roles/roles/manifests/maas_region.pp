class roles::maas_region {
  include roles::common

  include p_maas::regioncontroller::ha
}
