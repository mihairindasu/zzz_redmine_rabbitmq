# D:\redmine-plugins\redmine_rabbitmq\patches\issue_patch.rb

require_dependency 'issue'

module ZzzRedmineRabbitmq
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable # This is required in development mode

          # Add after_destroy callback
          after_destroy :trigger_after_destroy_hook
        end
      end

      module InstanceMethods

        def trigger_after_destroy_hook
          # Call your custom hook after destroy
          Redmine::Hook.call_hook(:controller_issues_after_destroy, { issue: self })
        end
      end
    end
  end
end

# Apply the patch
Issue.send(:include, ZzzRedmineRabbitmq::Patches::IssuePatch)
