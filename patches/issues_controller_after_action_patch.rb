
require_dependency 'issues_controller'

module ZzzRedmineRabbitmq
  module Patches
    module IssuesControllerAfterActionPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          after_action :modify_response_include_sprint_id, only: [:index, :show]
        end
      end

      module InstanceMethods
        def modify_response_include_sprint_id
          Rails.logger.info "IssuesController#modify_response_include_sprint_id"
          
          # Check if the request format is JSON / api call
          return unless request.format.json?

          begin
            modified_data = JSON.parse(response.body)

            if action_name == "show" && @issue.respond_to?(:sprint_id)
              modified_data["issue"]["sprint_id"] = @issue.sprint_id
            elsif action_name == "index" && @issues.first&.respond_to?(:sprint_id)
              modified_data["issues"].each_with_index do |issue_data, idx|
                issue_data["sprint_id"] = @issues[idx].sprint_id
              end
            end

            # Modify the response body directly
            response.body = modified_data.to_json
          rescue JSON::ParserError => e
            Rails.logger.error "Error parsing response JSON in IssuesController#modify_response_include_sprint_id: #{e.message}"
          end
        end
      end
    end
  end
end

# Apply the patch to the IssuesController
IssuesController.send(:include, ZzzRedmineRabbitmq::Patches::IssuesControllerAfterActionPatch)
