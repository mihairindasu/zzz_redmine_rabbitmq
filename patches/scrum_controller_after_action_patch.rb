scrum_plugin_path = Rails.root.join('plugins', 'scrum', 'app', 'controllers', 'scrum_controller.rb')

require_dependency scrum_plugin_path.to_s

module RedmineRabbitmq
  module Patches
    module ScrumControllerAfterActionPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          after_action :trigger_custom_hook, only: [:create_pbi, :update_pbi, :create_task, :update_task]
        end
      end

      module InstanceMethods
        # New method to trigger the custom hook
        def trigger_custom_hook
          # Check if the @pbi object is present
          Rails.logger.info "ScrumController#create_user_story"
          # Determine the correct issue object based on the action
          issue_object = case action_name
          when 'create_task', 'update_task'
            @task
          else
            @pbi
          end
          if issue_object && issue_object.persisted?
            # Call your custom hook
            Redmine::Hook.call_hook(:controller_issues_new_after_save, { issue: issue_object })
          end
        end
      end
    end
  end
end

# Apply the patch to the ScrumController
ScrumController.send(:include, RedmineRabbitmq::Patches::ScrumControllerAfterActionPatch)

