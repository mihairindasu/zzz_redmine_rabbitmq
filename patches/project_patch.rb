# D:\redmine-plugins\redmine_rabbitmq\patches\project_patch.rb

require_dependency 'project'

module RedmineRabbitmq
  module Patches
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable # This is required in development mode

          # Add after_save callback to trigger your custom hook
          after_save :trigger_custom_hook
        end
      end

      module InstanceMethods
        def trigger_custom_hook
          # Call your custom hook
          Redmine::Hook.call_hook(:controller_project_after_save, { project: self })
        end
      end
    end
  end
end

# Apply the patch
Project.send(:include, RedmineRabbitmq::Patches::ProjectPatch)
