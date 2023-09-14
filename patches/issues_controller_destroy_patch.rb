require_dependency 'issues_controller'

module RedmineRabbitmq
  module Patches
    module IssuesControllerDestroyPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :destroy_without_hook, :destroy
          alias_method :destroy, :destroy_with_hook
        end
      end

      module InstanceMethods
        def destroy_with_hook 
          # Fetch the issue directly from the database using params[:id]
          issue_to_be_deleted = Issue.find_by_id(params[:id])

          destroy_without_hook

          # Call your custom hook after the issue is destroyed
          if issue_to_be_deleted
            Redmine::Hook.call_hook(:controller_issues_after_destroy, { issue: issue_to_be_deleted })
          end
          
        end
      end
    end
  end
end

# Apply the patch to the IssuesController
IssuesController.send(:include, RedmineRabbitmq::Patches::IssuesControllerDestroyPatch)
