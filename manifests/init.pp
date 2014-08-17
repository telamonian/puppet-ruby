# Class: ruby
#
# This module installs a full rbenv-driven ruby stack
#
class ruby(
  $provider = $ruby::provider,
  $prefix   = $ruby::prefix,
  $user     = $ruby::user,
) {
  include boxen::config
  include ruby::build

  $provider_class = "ruby::${provider}"
  include $provider_class

  boxen::env_script { 'ruby':
    content  => template('ruby/ruby.sh'),
    priority => 'higher',
  }

  file { '/opt/rubies':
    ensure => directory,
    owner  => $user,
  }

  Class['ruby::build'] ->
    Ruby::Definition <| |> ->
    Class[$provider_class] ->
    Ruby <| |> ->
    Ruby_gem <| |>
}
