$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../config', __FILE__)
$LOAD_PATH.unshift File.expand_path('../patches', __FILE__)
$LOAD_PATH.unshift File.expand_path('../app/views', __FILE__)

require 'redmine'
require_dependency 'initializers/setup_rabbitmq'
require_dependency 'redmine_rabbitmq/hooks'
require_dependency 'project_patch'
require_dependency 'sprint_patch'
require_dependency 'issues_controller_after_action_patch'

if defined?(Sprint)
  Sprint.send(:include, RedmineRabbitmq::Patches::SprintPatch) unless Sprint.included_modules.include? RedmineRabbitmq::Patches::SprintPatch
else
  Rails.logger.warn "Scrum plugin not loaded. Skipping Sprint patch."
end

Redmine::Plugin.register :redmine_rabbitmq do
  name 'Redmine Rabbitmq plugin'
  author 'eConfaire ID'
  description 'This is a plugin for redmine that helps you send messages to RabbitMQ when certain events occur. The events are: issue creation, issue update, user login, project creation, project update, sprint creation, sprint update. It also has a rake task that can be used to send failed messages to RabbitMQ. And a patch to sprint model to get all sprints. For sprints it needs the Scrum plugin installed.'
  version '0.0.1'
  url 'https://econfaire.ro/'
  author_url 'https://econfaire.ro/'
  settings default: {
    'rabbitmq_host' => 'host.docker.internal',
    'rabbitmq_user' => '',
    'rabbitmq_password' => ''
  }, partial: '/settings/redmine_rabbitmq_settings'
end

RedmineRabbitmq.start_polling

