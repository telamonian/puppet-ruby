# Installs a ruby version with ruby-build..
# Takes ensure, env, and version params.
#
# Usage:
#
#     ruby::version { '1.9.3-p194': }

define ruby::version(
  $ensure  = 'installed',
  $env     = {},
  $version = $name
) {
  require ruby
  require ruby::build

  $alias_hash = hiera_hash('ruby::version::alias', {})

  if has_key($alias_hash, $version) {
    $to = $alias_hash[$version]

    ruby::alias { $version:
      ensure => $ensure,
      to     => $to,
    }
  } else {

    case $version {
      /jruby/: { require 'java' }
      default: { }
    }

    $default_env = {
      'CC' => '/usr/bin/cc',
    }

    if $::operatingsystem == 'Darwin' {
      require xquartz
      include homebrew::config
      include boxen::config
      ensure_resource('package', 'readline')
      Package['readline'] -> Ruby <| |>
    }

    $hierdata = hiera_hash('ruby::version::env', {})

    if has_key($hierdata, $::operatingsystem) {
      $os_env = $hierdata[$::operatingsystem]
    } else {
      $os_env = {}
    }

    if has_key($hierdata, $version) {
      $version_env = $hierdata[$version]
    } else {
      $version_env = {}
    }

    $_env = merge(merge(merge($default_env, $os_env), $version_env), $env)

    if has_key($_env, 'CC') and $_env['CC'] =~ /gcc/ {
      require gcc
    }
    
    # in theory, you can specify multiple patches per version in the ruby::patch variable, and the following puppetscript can handle it, but the rubybuild.rb provider (for now) will ignore all but the first
    $patch_hash = hiera('ruby::patch', {})
    if has_key($patch_hash, $version) {
      $patch_list = any2array($patch_hash[$version])
      $patch_titles = prefix($patch_list, "${::ruby::prefix}/cache/rubies/")
      $patch_sources = prefix($patch_list, "puppet:///modules/ruby/patches/${::osfamily}/${::lsbdistcodename}/")
      file { $patch_titles: 
        source => $patch_sources,
        mode   => '0644',
        before => Ruby[ $version ], 
      }
    }
    else {
      $patch_list = []
    }
    
    ruby { $version:
      ensure      => $ensure,
      environment => $_env,
      ruby_build  => "${ruby::build::prefix}/bin/ruby-build",
      user        => $ruby::user,
      patch       => $patch_list,
      provider    => rubybuild,
    }

  }

}
