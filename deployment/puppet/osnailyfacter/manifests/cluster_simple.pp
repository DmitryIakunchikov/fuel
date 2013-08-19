class osnailyfacter::cluster_simple {

  case $role {
    "controller" : {
      include osnailyfacter::test_controller

      class {'osnailyfacter::tinyproxy': }
      class { 'openstack::controller':
        admin_address           => $controller_internal_addresses[0],
        public_address          => $controller_public_addresses[0],
        public_interface        => $public_int,
        private_interface       => $fixed_interface,
        internal_address        => $controller_internal_addresses[0],
        floating_range          => $quantum ? { 'true' =>$floating_hash, default=>false},
        fixed_range             => $fixed_network_range,
        multi_host              => $multi_host,
        network_manager         => $network_manager,
        num_networks            => $num_networks,
        network_size            => $network_size,
        network_config          => $network_config,
        verbose                 => $verbose,
        debug                   => $debug,
        auto_assign_floating_ip => $bool_auto_assign_floating_ip,
        mysql_root_password     => $mysql_hash[root_password],
        admin_email             => $access_hash[email],
        admin_user              => $access_hash[user],
        admin_password          => $access_hash[password],
        keystone_db_password    => $keystone_hash[db_password],
        keystone_admin_token    => $keystone_hash[admin_token],
        keystone_admin_tenant   => $access_hash[tenant],
        glance_db_password      => $glance_hash[db_password],
        glance_user_password    => $glance_hash[user_password],
        nova_db_password        => $nova_hash[db_password],
        nova_user_password      => $nova_hash[user_password],
        nova_rate_limits        => $nova_rate_limits,
        queue_provider          => $::queue_provider,
        rabbit_password         => $rabbit_hash[password],
        rabbit_user             => $rabbit_hash[user],
        qpid_password           => $rabbit_hash[password],
        qpid_user               => $rabbit_hash[user],
        export_resources        => false,
        quantum                 => $quantum,
        quantum_user_password         => $quantum_hash[user_password],
        quantum_db_password           => $quantum_hash[db_password],
        quantum_network_node          => $quantum,
        quantum_netnode_on_cnt        => true,
        quantum_gre_bind_addr         => $quantum_gre_bind_addr,
        quantum_external_ipinfo       => $external_ipinfo,
        tenant_network_type           => $tenant_network_type,
        segment_range                 => $segment_range,
        cinder                  => true,
        cinder_user_password    => $cinder_hash[user_password],
        cinder_db_password      => $cinder_hash[db_password],
        cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
        cinder_volume_group     => "cinder",
        manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
        use_syslog              => true,
        syslog_log_level        => $syslog_log_level,
        syslog_log_facility_glance   => $syslog_log_facility_glance,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_nova => $syslog_log_facility_nova,
        syslog_log_facility_keystone => $syslog_log_facility_keystone,
        cinder_rate_limits      => $cinder_rate_limits,
        horizon_use_ssl         => $horizon_use_ssl,
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $start_guests_on_host_boot }
      nova_config { 'DEFAULT/use_cow_images': value => $use_cow_images }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $compute_scheduler_driver }
 if $::quantum {
    class { '::openstack::quantum_router':
      db_host               => $controller_internal_addresses[0],
      service_endpoint      => $controller_internal_addresses[0],
      auth_host             => $controller_internal_addresses[0],
      nova_api_vip          => $controller_internal_addresses[0],
      internal_address      => $internal_address,
      public_interface      => $public_int,
      private_interface     => $fixed_interface,
      floating_range        => $floating_hash,
      fixed_range           => $fixed_network_range,
      create_networks       => $create_networks,
      verbose               => $verbose,
      debug                 => $debug,
      queue_provider        => $queue_provider,
      rabbit_password       => $rabbit_hash[password],
      rabbit_user           => $rabbit_hash[user],
      rabbit_ha_virtual_ip  => $controller_internal_addresses[0],
      rabbit_nodes          => [$controller_internal_addresses[0]],
      qpid_password         => $rabbit_hash[password],
      qpid_user             => $rabbit_hash[user],
      qpid_nodes            => [$controller_internal_addresses[0]],
      quantum               => $quantum,
      quantum_user_password => $quantum_hash[user_password],
      quantum_db_password   => $quantum_hash[db_password],
      quantum_gre_bind_addr => $quantum_gre_bind_addr,
      quantum_network_node  => true,
      quantum_netnode_on_cnt=> $quantum,
      tenant_network_type   => $tenant_network_type,
      segment_range         => $segment_range,
      external_ipinfo       => $external_ipinfo,
      api_bind_address      => $internal_address,
      use_syslog            => $use_syslog,
      syslog_log_level      => $syslog_log_level,
      syslog_log_facility   => $syslog_log_facility_quantum,
    }
  }


      class { 'openstack::auth_file':
        admin_user           => $access_hash[user],
        admin_password       => $access_hash[password],
        keystone_admin_token => $keystone_hash[admin_token],
        admin_tenant         => $access_hash[tenant],
        controller_node      => $controller_internal_addresses[0],
      }


      # glance_image is currently broken in fuel

      # glance_image {'testvm':
      #   ensure           => present,
      #   name             => "Cirros testvm",
      #   is_public        => 'yes',
      #   container_format => 'ovf',
      #   disk_format      => 'raw',
      #   source           => '/opt/vm/cirros-0.3.0-x86_64-disk.img',
      #   require          => Class[glance::api],
      # }

      class { 'openstack::img::cirros':
        os_username               => shellescape($access_hash[user]),
        os_password               => shellescape($access_hash[password]),
        os_tenant_name            => shellescape($access_hash[tenant]),
        img_name                  => "TestVM",
        stage                     => 'glance-image',
      }
      if !$quantum {
      nova_floating_range{ $floating_ips_range:
        ensure          => 'present',
        pool            => 'nova',
        username        => $access_hash[user],
        api_key         => $access_hash[password],
        auth_method     => 'password',
        auth_url        => "http://${controller_internal_addresses[0]}:5000/v2.0/",
        authtenant_name => $access_hash[tenant],
      }
      }

      Class[glance::api]        -> Class[openstack::img::cirros]
    }

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $public_int,
        private_interface      => $fixed_interface,
        internal_address       => $internal_address,
        libvirt_type           => $libvirt_type,
        fixed_range            => $fixed_network_range,
        network_manager        => $network_manager,
        network_config         => $network_config,
        multi_host             => $multi_host,
        sql_connection         => "mysql://nova:${nova_hash[db_password]}@${controller_internal_addresses[0]}/nova",
        nova_user_password     => $nova_hash[user_password],
        queue_provider         => $::queue_provider,
        rabbit_nodes           => $controller_internal_addresses,
        rabbit_password        => $rabbit_hash[password],
        rabbit_user            => $rabbit_user,
        auto_assign_floating_ip => $bool_auto_assign_floating_ip,
        qpid_nodes             => $controller_internal_addresses,
        qpid_password          => $rabbit_hash[password],
        qpid_user              => $rabbit_user,
        glance_api_servers     => "${controller_internal_addresses[0]}:9292",
        vncproxy_host          => $controller_public_addresses[0],
        vnc_enabled            => true,
        #ssh_private_key        => 'puppet:///ssh_keys/openstack',
        #ssh_public_key         => 'puppet:///ssh_keys/openstack.pub',
        quantum                => $quantum,
        quantum_host           => $quantum_host,
        quantum_sql_connection => $quantum_sql_connection,
        quantum_user_password  => $quantum_hash[user_password],
        tenant_network_type    => $tenant_network_type,
        service_endpoint       => $controller_internal_addresses[0],
        cinder                 => true,
        cinder_user_password   => $cinder_hash[user_password],
        cinder_db_password     => $cinder_hash[db_password],
        cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
        cinder_volume_group     => "cinder",
        manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
        db_host                => $controller_internal_addresses[0],
        verbose                => $verbose,
        debug                   => $debug,
        use_syslog             => true,
        syslog_log_level       => $syslog_log_level,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        state_path             => $nova_hash[state_path],
        nova_rate_limits       => $nova_rate_limits,
        cinder_rate_limits     => $cinder_rate_limits
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $start_guests_on_host_boot }
      nova_config { 'DEFAULT/use_cow_images': value => $use_cow_images }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $compute_scheduler_driver }
    }

    "cinder" : {
      include keystone::python
      package { 'python-amqp':
        ensure => present
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${controller_internal_addresses[0]}/cinder?charset=utf8",
        glance_api_servers   => "${controller_internal_addresses[0]}:9292",
        queue_provider       => $::queue_provider,
        rabbit_password      => $rabbit_hash[password],
        rabbit_host          => false,
        rabbit_nodes         => [$controller_internal_addresses[0]],
        qpid_password        => $rabbit_hash[password],
        qpid_user            => $rabbit_hash[user],
        qpid_nodes           => [$controller_internal_addresses[0]],
        volume_group         => 'cinder',
        manage_volumes       => true,
        enabled              => true,
        auth_host            => $controller_internal_addresses[0],
        iscsi_bind_host      => $cinder_iscsi_bind_addr,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $syslog_log_facility_cinder,
        syslog_log_level     => $syslog_log_level,
        debug                => $debug ? { true => 'True', default=>'False' },
        verbose              => $verbose ? { false => 'False', default=>'True' },
        use_syslog           => true,
      }
   }
  }
}
