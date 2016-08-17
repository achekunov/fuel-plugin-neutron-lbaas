#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

class lbaas {
  include lbaas::params

  package { $lbaas::params::lbaas_package_name:
    ensure => present,
  }

  neutron_config {
     "service_providers/service_provider": value => $lbaas::params::lbaas_service_provider;
  }

  ini_subsetting {"enable_lbaas_plugin":
    ensure               => present,
    section              => 'DEFAULT',
    key_val_separator    => '=',
    path                 => $lbaas::params::neutron_conf_file,
    setting              => 'service_plugins',
    subsetting           => $lbaas::params::lbaas_service_plugin_name,
    subsetting_separator => ',',
  }

  lbaas_config {
    "DEFAULT/device_driver": value => 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver';
    "DEFAULT/interface_driver": value => 'neutron.agent.linux.interface.OVSInterfaceDriver';
    "haproxy/user_group": value => $lbaas::params::usergroup;
  }

  exec { "enable_lbaas":
    command => "/bin/sed -i \"s/'enable_lb': False/'enable_lb': True/\" $lbaas::params::horizon_settings_file",
    unless  => "/bin/egrep \"'enable_lb': True\" $lbaas::params::horizon_settings_file",
    notify  => Service[$lbaas::params::httpd_service_name],
  }

  service { 'neutron-server':
    ensure  => running,
    enable  => true,
    require => Package[$lbaas::params::lbaas_package_name],
  }

  service { 'neutron-lbaas-agent':
    ensure  => running,
    enable  => true,
    require => Package[$lbaas::params::lbaas_package_name],
  }

  service { $lbaas::params::httpd_service_name:
    enable  => true,
    ensure  => running,
  }

}
