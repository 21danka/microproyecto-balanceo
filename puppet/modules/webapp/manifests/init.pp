class webapp {
  package { 'apache2':
    ensure => installed,
  }

service { 'apache2':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['apache2'],
  }

  file { '/var/www/html/index.html':
    ensure  => file,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    source  => 'puppet:///modules/webapp/index.html',
    require => Package['apache2'],
  }
}
