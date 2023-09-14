# # D:\redmine-plugins\redmine_rabbitmq\config\setup_rabbitmq.rb

module RedmineRabbitmq
    class RabbitmqConnection
      MAX_RETRIES = 2
      def self.connect
        host = Setting.plugin_redmine_rabbitmq['rabbitmq_host']
        user = Setting.plugin_redmine_rabbitmq['rabbitmq_user']
        password = Setting.plugin_redmine_rabbitmq['rabbitmq_password']
  
        retries = 0

        begin
          # Establish a connection to RabbitMQ
          conn = Bunny.new(host: host, user: user, password: password)
          conn.start

          # Create a channel
          channel = conn.create_channel

          # Declare a direct exchange
          exchange = channel.direct("redmine.direct.durable", durable: true)

          # Declare a queue
          queue = channel.queue("redmine.queue.durable", durable: true)

          # Bind the queue to the exchange
           queue.bind(exchange, routing_key: 'redmine.cru_projects_key')

           queue.bind(exchange, routing_key: 'redmine.cru_issues_key')

           queue.bind(exchange, routing_key: 'redmine.cru_sprints_key')

           queue.bind(exchange, routing_key: 'redmine.d_projects_key')

           queue.bind(exchange, routing_key: 'redmine.d_issues_key')

           queue.bind(exchange, routing_key: 'redmine.d_sprints_key')

          return channel, exchange, conn
        rescue Bunny::TCPConnectionFailed => e
          Rails.logger.error "Failed to connect to RabbitMQ: #{e.message}"
          retries += 1
          retry if retries < MAX_RETRIES
          # Store messages locally if needed
        rescue => e
          Rails.logger.error "Error: #{e.message}"
        end
      end
    end
  end
  
