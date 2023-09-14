# D:\redmine-plugins\redmine_rabbitmq\lib\redmine_rabbitmq\hooks.rb

module ZzzRedmineRabbitmq
  FAILED_MESSAGES_FILE = "#{Rails.root}/failed_messages.log"
  TEMP_FAILED_MESSAGES_FILE = "#{Rails.root}/temp_failed_messages.log"
  RETRY_TIME = 600 # seconds / 10 minutes
  def self.start_polling
    Thread.new do
      loop do
        begin
          sleep RETRY_TIME # Sleep for 1 hour
          self.retry_failed_messages
        rescue => e
          # Log the error, so you know if something went wrong
          Rails.logger.error "Error in retrying messages: #{e.message}"
        end
      end
    end
  end

  def self.retry_failed_messages
     # Check if the necessary settings are provided
    unless Setting.plugin_zzz_redmine_rabbitmq['rabbitmq_host'].present? &&
    Setting.plugin_zzz_redmine_rabbitmq['rabbitmq_user'].present? &&
    Setting.plugin_zzz_redmine_rabbitmq['rabbitmq_password'].present?

    Rails.logger.warn "RabbitMQ settings not configured. Skipping retry of failed messages."
    return
    end

    return unless File.exist?(FAILED_MESSAGES_FILE)
  
    failed_messages = []
  
    File.open(FAILED_MESSAGES_FILE, 'r').each_line do |line|
      data = JSON.parse(line)
      message = data["data"]
      routing_key = data["routing_key"]
      
      begin
        channel, exchange, conn = ZzzRedmineRabbitmq::RabbitmqConnection.connect
        exchange.publish(message, routing_key: routing_key, persistent: true)
        conn.close
      rescue => e
        Rails.logger.error "Retry failed for message: #{e.message}"
        failed_messages << line.strip
      end
    end
  
    # Write only the failed messages back to the FAILED_MESSAGES_FILE
    File.open(FAILED_MESSAGES_FILE, 'w') do |f|
      failed_messages.each { |msg| f.puts(msg) }
    end
  end
  

  class Hooks < Redmine::Hook::ViewListener
    def send_message_to_rabbitmq(message, routing_key)
      # Check if the necessary settings are provided
      unless Setting.plugin_zzz_redmine_rabbitmq['rabbitmq_host'].present? &&
             Setting.plugin_zzz_redmine_rabbitmq['rabbitmq_user'].present? &&
             Setting.plugin_zzz_redmine_rabbitmq['rabbitmq_password'].present?
        
        Rails.logger.warn "RabbitMQ settings not configured. Storing message locally."
        store_message_locally(message, routing_key)
        return
      end
    
      retries = 0
      begin
        channel, exchange, conn = ZzzRedmineRabbitmq::RabbitmqConnection.connect
        exchange.publish(message, routing_key: routing_key, persistent: true)
        conn.close
    
        # If the message was sent successfully, try to send the failed messages
        ZzzRedmineRabbitmq.retry_failed_messages
      rescue => e
        Rails.logger.error "Failed to send message: #{e.message}"
        store_message_locally(message, routing_key)
      end
    end
    def store_message_locally(message, routing_key)
      begin
        File.open(ZzzRedmineRabbitmq::FAILED_MESSAGES_FILE, 'a') do |f|
          f.puts({data: message, routing_key: routing_key}.to_json)
        end
      rescue => e
        Rails.logger.error "Failed to write message to file: #{e.message}"
      end
    end    

    def controller_account_success_authentication_after(context = {})
      user = context[:user]
      # Send a message to RabbitMQ
      # send_message_to_rabbitmq("User #{user.id} logged in.", 'redmine.issues_key')
    end
    # Hook for when an issue is created or updated
    def controller_project_after_save(context = {})
      project = context[:project]
      Rails.logger.warn "Project save hook triggered id:#{project.id}"
      # Send a message to RabbitMQ
      send_message_to_rabbitmq(project.to_json, 'redmine.cru_projects_key')
    end

    def controller_project_after_destroy(context = {})
      project = context[:project] 
      Rails.logger.warn "Project destroy hook triggered id:#{project.id}"
      # Send a message to RabbitMQ
      send_message_to_rabbitmq(project.to_json, 'redmine.d_projects_key')
    end

    # Hook for when a project is created or updated
    def controller_issues_new_after_save(context = {})
      issue = context[:issue]
      Rails.logger.warn "Issue new hook triggered id:#{issue.id}"
      # Send a message to RabbitMQ
      send_message_to_rabbitmq(issue.to_json, 'redmine.cru_issues_key')
    end
    def controller_issues_edit_after_save(context = {})
      issue = context[:issue]
      Rails.logger.warn "Issue edit hook triggered id:#{issue.id}"
      # Send a message to RabbitMQ
      send_message_to_rabbitmq(issue.to_json, 'redmine.cru_issues_key')
    end
    def controller_issues_after_destroy(context = {})
      issue = context[:issue]
      Rails.logger.warn "Issue destroy hook triggered id:#{issue.id}"
      # Send a message to RabbitMQ
      send_message_to_rabbitmq(issue.to_json, 'redmine.d_issues_key')
    end

    def controller_sprint_after_save(context = {})
      sprint = context[:sprint]
      Rails.logger.warn "Sprint hook triggered id:#{sprint.id}"
      # Send a message to RabbitMQ
      send_message_to_rabbitmq(sprint.to_json, 'redmine.cru_sprints_key')
    end

    def controller_sprint_after_destroy(context = {})
      sprint = context[:sprint]
      Rails.logger.warn "Sprint destroy hook triggered id:#{sprint.id}"
      # Send a message to RabbitMQ
      send_message_to_rabbitmq(sprint.to_json, 'redmine.d_sprints_key')
    end
  end
end
