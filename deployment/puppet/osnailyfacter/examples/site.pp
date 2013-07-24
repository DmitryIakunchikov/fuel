$openstack_version = {
  'keystone'   => 'latest',
  'glance'     => 'latest',
  'horizon'    => 'latest',
  'nova'       => 'latest',
  'novncproxy' => 'latest',
  'cinder'     => 'latest',
}

tag("${deployment_id}::${::environment}")

#Stages configuration
stage {'first': } ->
stage {'openstack-custom-repo': } ->
stage {'netconfig': } ->
stage {'corosync_setup': } ->
stage {'cluster_head': } ->
stage {'openstack-firewall': } -> Stage['main']

stage {'glance-image':
  require => Stage['main'],
}

case $::operatingsystem {
  'redhat' : { 
          $queue_provider = 'qpid'
          $custom_mysql_setup_class = 'mysql_pacemaker'
  }
  default: {
    $queue_provider='rabbitmq'
    $custom_mysql_setup_class='galera'
  }
}

class os_common {
  class {'osnailyfacter::network_setup': stage => 'netconfig'}
  class {'openstack::firewall': stage => 'openstack-firewall'}

  # Workaround for fuel bug with firewall
  firewall {'003 remote rabbitmq ':
    sport   => [ 4369, 5672, 41055, 55672, 61613 ],
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }
}
node default {
  case $deployment_mode {
    "singlenode": { 
      include osnailyfacter::cluster_simple 
      class {'os_common':}
      }
    "multinode": { 
      include osnailyfacter::cluster_simple
      class {'os_common':}
      }
    "ha": { 
      include osnailyfacter::cluster_ha
      class {'os_common':}
      }
    "rpmcache": { include osnailyfacter::rpmcache }
  }

}
