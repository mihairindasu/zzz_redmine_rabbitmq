# Assuming the file path is: D:\redmine-plugins\redmine_rabbitmq\patches\sprint_patch.rb

scrum_plugin_path = Rails.root.join('plugins', 'scrum', 'app', 'models', 'sprint.rb')
# require_dependency '/usr/src/redmine/plugins/scrum/app/models/sprint'  # Make sure this is the correct path to the Sprint model in Redmine
require_dependency scrum_plugin_path.to_s

module RedmineRabbitmq
  module Patches
    module SprintPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable # This is required in development mode

          # Add after_save callback to trigger your custom hook for Sprint
          after_save :trigger_sprint_custom_hook

           # Add after_destroy callback for Sprint
          after_destroy :trigger_sprint_after_destroy
        end
      end

      module InstanceMethods
        def trigger_sprint_custom_hook
          # Call your custom hook for Sprint
          Redmine::Hook.call_hook(:controller_sprint_after_save, { sprint: self })
        end

        def trigger_sprint_after_destroy
          # Call your custom hook after Sprint is destroyed
          Redmine::Hook.call_hook(:controller_sprint_after_destroy, { sprint: self })
        end
      end
    end
  end
end

# Apply the patch to the Sprint model
# Sprint.send(:include, RedmineRabbitmq::Patches::SprintPatch)
