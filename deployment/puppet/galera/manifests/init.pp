# 
# wget https://launchpad.net/codership-mysql/5.5/5.5.23-23.6/+download/mysql-server-wsrep-5.5.23-23.6-amd64.deb
# wget https://launchpad.net/galera/2.x/23.2.1/+download/galera-23.2.1-amd64.deb
# aptitude install mysql-client libdbd-mysql-perl libdbi-perl
# aptitude install libssl0.9.8
# dpkg -i mysql-server-wsrep-5.5.23-23.6-amd64.deb 
# dpkg -i galera-23.2.1-amd64.deb 
# vi /etc/mysql/conf.d/wsrep.cnf 
# /etc/init.d/mysql start
# 
class galera($cluster_name, $master_ip = false, $node_address = $ipaddress_eth0, $setup_multiple_gcomm = true, $node_addresses=[$ipaddress_eth0]) {

  include galera::params

  $mysql_user         = $::galera::params::mysql_user
  $mysql_password     = $::galera::params::mysql_password
  $libgalera_prefix   = $::galera::params::libgalera_prefix

  # $mysql_wsrep_prefix = 'https://launchpad.net/codership-mysql/5.5/5.5.23-23.6/+download'
  # $galera_prefix      = 'https://launchpad.net/galera/2.x/23.2.1/+download'
  #$mysql_wsrep_prefix = 'http://download.mirantis.com/epel-fuel/x86_64'
  #$galera_prefix      = $mysql_wsrep_prefix

  case $::osfamily {
    'RedHat': {
#      $mysql_wsrep_prefix = 'http://download.mirantis.com/epel-fuel/x86_64'
#      $galera_prefix      = $mysql_wsrep_prefix
#      $pkg_prefix  = $mysql_wsrep_prefix
#      $pkg_version = '5.5.28-1.el6.x86_64'

      if (!$::selinux=='false') and !defined(Class['selinux']) {
        class { 'selinux' :
          mode   => 'disabled',
          before => Package['MySQL-server']
        }
      }

      # install custom dependencies outside repository
#      Galera::Pkg_add {
#        pkg_prefix  => $pkg_prefix,
#        pkg_version => $pkg_version,
#        before      => Package['MySQL-server']
#      }

#      galera::pkg_add { 'MySQL-client': }
#      galera::pkg_add { 'MySQL-shared': }

      file { '/etc/init.d/mysql' :
        ensure  => present,
        mode => 755,
        source  => 'puppet:///modules/galera/mysql.init',
        require => Package['MySQL-server'],
        before  => Service['mysql-galera']
      }

      file { '/etc/my.cnf' :
        ensure  => present,
        source  => 'puppet:///modules/galera/my.cnf',
        before  => Service['mysql-galera']
      }

      package { 'MySQL-client' :
        ensure => present,
        before => Package['MySQL-server']
      }

      package { 'MySQL-shared' :
        ensure => present,
        before => Package['MySQL-server']
      }

#      package { 'mysql-server' :
#        ensure => present,
#        require => Package['MySQL-client', 'MySQL-shared'],
#        before => Service['mysql-galera']
#      }

      package { 'wget' :
        ensure => present,
#        before => Exec['download-wsrep', 'download-galera']
      }

      package { 'perl' :
        ensure => present,
        before => Package['MySQL-client']
      }
    }
    'Debian': {
#      $mysql_wsrep_prefix = 'http://download.mirantis.com/epel-fuel/x86_64'
#      $galera_prefix      = $mysql_wsrep_prefix
      
#      $pkg_prefix  = $mysql_wsrep_prefix
#      $pkg_version = 'wsrep-5.5.28-23.7-amd64'

      if (!$::selinux=='false') and !defined(Class['selinux']) {
        class { 'selinux' :
          mode   => 'disabled',
          before => Package['MySQL-server']
        }
      }

      # install custom dependencies outside repository
#      Galera::Pkg_add {
#        pkg_prefix  => $pkg_prefix,
#        pkg_version => $pkg_version,
#        before      => Package['MySQL-server']
#      }

#      galera::pkg_add { 'MySQL-client': }
#      galera::pkg_add { 'MySQL-shared': }

      file { '/etc/init.d/mysql' :
        ensure  => present,
        mode => 755,
        source  => 'puppet:///modules/galera/mysql.init',
        require => Package['MySQL-server'],
        before  => Service['mysql-galera']
      }

      file { '/etc/my.cnf' :
        ensure  => present,
        source  => 'puppet:///modules/galera/my.cnf',
        before  => Service['mysql-galera']
      }

      package { 'wget' :
        ensure => present,
#        before => Exec['download-wsrep', 'download-galera']
      }

      package { 'perl' :
        ensure => present,
        before => Package['mysql-client']
      }
      
      package { 'mysql-client' :
        ensure => present,
        before => Package['MySQL-server']
      }

      package { 'mysql-common' :
        ensure => present,
        before => Package['MySQL-server']
      }

      package {'libc6': 
      ensure=>latest,
      before => Package['MySQL-server']
      }
    }
  }

  service { "mysql-galera" :
    name        => "mysql",
    enable      => true,
    ensure      => "running",
    require     => [Package["MySQL-server", "galera"]],
    hasrestart  => true,
    hasstatus   => true,
  }

  package { [$::galera::params::libssl_package, $::galera::params::libaio_package] :
    ensure      => present,
    before      => Package["galera", "MySQL-server"]
  }

  package { "MySQL-server" :
    ensure      => $::galera::params::mysql_version,
    name 	=> $::galera::params::mysql_server_name,
    provider    => $::galera::params::pkg_provider,
#    before => Package['Python-mysqldb']
    require     => [Package['galera'],File["/etc/mysql/conf.d/wsrep.cnf"]]
#    source      => "/tmp/${::galera::params::mysql_server_package}",
#    require     => [Exec["download-wsrep"]]
  }

#  exec { "download-wsrep" :
#    command     => "/usr/bin/wget -P/tmp ${mysql_wsrep_prefix}/${::galera::params::mysql_server_package}",
#    creates     => "/tmp/${::galera::params::mysql_server_package}"
#  }

  package { "galera" :
    ensure      => $::galera::params::galera_version,
#    require     => Package['MySQL-client'],
    provider    => $::galera::params::pkg_provider,
#    source      => "/tmp/${::galera::params::galera_package}",
#    require     => Exec["download-galera"],
  }
  # Uncomment the following Exec and sequence arrow to obtain full MySQL server installation log
#  ->
#  exec { "debug -mysql-server-installation" :
#    command     => "/usr/bin/yum -d 10 -e 10 -y install MySQL-server 2>&1 | tee mysql_install.log",
#    before => Package["MySQL-server"],
#    logoutput => true,
#  }

#  exec { "download-galera" :
#    command     => "/usr/bin/wget -P/tmp ${galera_prefix}/${::galera::params::galera_package}",
#    creates     => "/tmp/${::galera::params::galera_package}",
#  }

  file { ["/etc/mysql", "/etc/mysql/conf.d" ] :
    ensure => directory,
  }
if $::galera_gcomm_empty=="true" {

  file { "/etc/mysql/conf.d/wsrep.cnf" :
    ensure      => present,
    content     => template("galera/wsrep.cnf.erb"),
    require => [File["/etc/mysql/conf.d"], File["/etc/mysql"]],
 ## require     => Package["galera"],
  }
  File["/etc/mysql/conf.d/wsrep.cnf"]->Exec['set-mysql-password']
  File["/etc/mysql/conf.d/wsrep.cnf"]~>Exec['set-mysql-password']
  File["/etc/mysql/conf.d/wsrep.cnf"]->Service['mysql-galera']
  File["/etc/mysql/conf.d/wsrep.cnf"]~>Service['mysql-galera']
  File["/etc/mysql/conf.d/wsrep.cnf"]->Package['MySQL-server']
}
  file { "/tmp/wsrep-init-file" :
    ensure      => present,
    content     => template("galera/wsrep-init-file.erb"),
    ## require     => Package["galera"],
  }
  exec { "set-mysql-password" :
    unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
    command     => "/usr/bin/mysqld_safe --init-file=/tmp/wsrep-init-file --port=3307 &",
    require   => [Package["MySQL-server"],File['/tmp/wsrep-init-file']],
    subscribe => Package["MySQL-server"],
    refreshonly => true,
  }

  exec { "wait-initial-sync" :
    require     => Exec["set-mysql-password"],
    subscribe   => Exec["set-mysql-password"],
    before	=> Exec["kill-initial-mysql"],
    logoutput   => true,
    command     => "/usr/bin/mysql -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q Synced && sleep 10",
    try_sleep   => 5,
    tries       => 60,
    refreshonly => true,
  }


  exec {"kill-initial-mysql":
	path   => "/usr/bin:/usr/sbin:/bin:/sbin",
      command   => "killall -w mysqld && ( killall -w -9 mysqld_safe || : ) && sleep 10",
#      onlyif    => "pidof mysqld",
      try_sleep   => 5,
      tries       => 6,
      before     => Service["mysql-galera"],
      require => Exec["set-mysql-password"],
      subscribe => Exec["wait-initial-sync"],
    refreshonly => true,
      }

  exec {"rm-init-file":
  command =>"/bin/rm /tmp/wsrep-init-file",
  require => Exec["kill-initial-mysql"],
  }

  exec { "wait-for-synced-state" :
    require     => [Exec["kill-initial-mysql"],Service['mysql-galera']],
    logoutput   => true,
    command     => "/usr/bin/mysql -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q Synced && sleep 10",
    try_sleep   => 5,
    tries       => 60,
  }

#  stage { 'after_main': require => Stage['main'] }

  class {'galera::galera_master_final_config':
#      stage => 'after_main',
      require     => Exec["wait-for-haproxy-mysql-backend"],
      master_ip => $master_ip,
      node_addresses => $node_addresses,
      node_address   => $node_address,
  }

}
