$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../config', __FILE__)
$LOAD_PATH.unshift File.expand_path('../patches', __FILE__)
$LOAD_PATH.unshift File.expand_path('../app/views', __FILE__)

require 'redmine'
require_dependency 'initializers/setup_rabbitmq'
require_dependency 'redmine_rabbitmq/hooks'
require_dependency 'project_patch'
require_dependency 'sprint_patch'

if defined?(Sprint)
  Sprint.send(:include, RedmineRabbitmq::Patches::SprintPatch) unless Sprint.included_modules.include? RedmineRabbitmq::Patches::SprintPatch
else
  Rails.logger.warn "Scrum plugin not loaded. Skipping Sprint patch."
end

Redmine::Plugin.register :redmine_rabbitmq do
  name 'Redmine Rabbitmq plugin'
  author 'eConfaire ID'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'https://econfaire.ro/'
  settings default: {
    'rabbitmq_host' => 'host.docker.internal',
    'rabbitmq_user' => '',
    'rabbitmq_password' => ''
  }, partial: '/settings/redmine_rabbitmq_settings'
end

RedmineRabbitmq.start_polling

