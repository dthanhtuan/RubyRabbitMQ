# frozen_string_literal: true

require 'bunny'

module Rabbitmq
  module Exchange
    class Subscriber
      # Subscribe to a fanout exchange (all subscribers get all messages)
      def self.subscribe_to_exchange(exchange_name, subscriber_name)
        connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
        connection.start

        channel = connection.create_channel
        # Create the same fanout exchange
        exchange = channel.fanout(exchange_name, durable: true)

        # Create a unique queue for this subscriber (temporary, auto-delete when subscriber disconnects)
        queue = channel.queue("#{exchange_name}.#{subscriber_name}", exclusive: false, auto_delete: true)

        # Bind the queue to the exchange
        queue.bind(exchange)

        Rails.logger.info "Exchange subscriber '#{subscriber_name}' connected to exchange '#{exchange_name}'"

        begin
          queue.subscribe(block: true) do |delivery_info, properties, body|
            Rails.logger.info "Exchange subscriber '#{subscriber_name}' received: #{body}"

            # Execute custom processing block if provided
            if block_given?
              yield(delivery_info, properties, body)
            else
              # Default processing
              process_message(subscriber_name, body)
            end
          end
        rescue Interrupt => _
          Rails.logger.info "Exchange subscriber '#{subscriber_name}' shutting down..."
        ensure
          connection.close
        end
      end

      # Subscribe to a topic exchange with routing key patterns
      def self.subscribe_to_topic(exchange_name, routing_pattern, subscriber_name)
        connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
        connection.start

        channel = connection.create_channel
        # Create the same topic exchange
        exchange = channel.topic(exchange_name, durable: true)

        # Create a unique queue for this subscriber
        queue = channel.queue("#{exchange_name}.#{subscriber_name}", exclusive: false, auto_delete: true)

        # Bind the queue to the exchange with routing pattern
        queue.bind(exchange, routing_key: routing_pattern)

        Rails.logger.info "Topic subscriber '#{subscriber_name}' connected to topic exchange '#{exchange_name}' with pattern '#{routing_pattern}'"

        begin
          queue.subscribe(block: true) do |delivery_info, properties, body|
            Rails.logger.info "Topic subscriber '#{subscriber_name}' received message with routing key '#{delivery_info.routing_key}': #{body}"

            # Execute custom processing block if provided
            if block_given?
              yield(delivery_info, properties, body)
            else
              # Default processing
              process_message(subscriber_name, body, delivery_info.routing_key)
            end
          end
        rescue Interrupt => _
          Rails.logger.info "Topic subscriber '#{subscriber_name}' shutting down..."
        ensure
          connection.close
        end
      end

      # Subscribe to a direct exchange with a specific routing key (routing pattern)
      def self.subscribe_to_direct(exchange_name, routing_key, subscriber_name)
        connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
        connection.start

        channel = connection.create_channel
        # Create the same direct exchange
        exchange = channel.direct(exchange_name, durable: true)

        # Create a unique queue for this subscriber
        queue = channel.queue("#{exchange_name}.#{subscriber_name}", exclusive: false, auto_delete: true)

        # Bind the queue to the exchange with the specific routing key
        queue.bind(exchange, routing_key: routing_key)

        Rails.logger.info "Direct subscriber '#{subscriber_name}' connected to direct exchange '#{exchange_name}' with routing key '#{routing_key}'"

        begin
          queue.subscribe(block: true) do |delivery_info, properties, body|
            Rails.logger.info "Direct subscriber '#{subscriber_name}' received message with routing key '#{delivery_info.routing_key}': #{body}"

            if block_given?
              yield(delivery_info, properties, body)
            else
              process_message(subscriber_name, body, delivery_info.routing_key)
            end
          end
        rescue Interrupt => _
          Rails.logger.info "Direct subscriber '#{subscriber_name}' shutting down..."
        ensure
          connection.close
        end
      end

      # Subscribe to a headers exchange. `headers_hash` should match subscriber binding criteria
      # Example headers_hash: { 'x-match' => 'all', 'type' => 'report' }
      def self.subscribe_to_headers(exchange_name, headers_hash, subscriber_name)
        connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
        connection.start

        channel = connection.create_channel
        # Create the same headers exchange
        exchange = channel.headers(exchange_name, durable: true)

        # Create a unique queue for this subscriber
        queue = channel.queue("#{exchange_name}.#{subscriber_name}", exclusive: false, auto_delete: true)

        # Bind the queue to the headers exchange with the provided headers arguments
        queue.bind(exchange, arguments: headers_hash)

        Rails.logger.info "Headers subscriber '#{subscriber_name}' connected to headers exchange '#{exchange_name}' with headers #{headers_hash.inspect}"

        begin
          queue.subscribe(block: true) do |delivery_info, properties, body|
            received_headers = properties.headers || {}
            Rails.logger.info "Headers subscriber '#{subscriber_name}' received message with headers #{received_headers.inspect}: #{body}"

            if block_given?
              yield(delivery_info, properties, body)
            else
              process_message(subscriber_name, body)
            end
          end
        rescue Interrupt => _
          Rails.logger.info "Headers subscriber '#{subscriber_name}' shutting down..."
        ensure
          connection.close
        end
      end

      private

      def self.process_message(subscriber_name, message, routing_key = nil)
        # Default message processing - override this method or pass a block
        Rails.logger.info "Processing message in exchange subscriber '#{subscriber_name}': #{message}"
        if routing_key
          Rails.logger.info "Routing key: #{routing_key}"
        end

        # Add your specific message processing logic here
        # For example: send notifications, update database, trigger other services, etc.
      end
    end
  end
end

