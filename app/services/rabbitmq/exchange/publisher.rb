# frozen_string_literal: true

require "bunny"

module Rabbitmq
  module Exchange
    class Publisher
      # Publish to fanout exchange (all subscribers receive the message)
      def self.broadcast(exchange_name, message)
        connection = Bunny.new(hostname: ENV.fetch("RABBITMQ_HOST", "localhost"))
        connection.start

        channel = connection.create_channel
        exchange = channel.fanout(exchange_name, durable: true)
        exchange.publish(message, persistent: true)

        Rails.logger.info "Broadcasted message to exchange '#{exchange_name}': #{message}"

        connection.close
      end

      # Publish to topic exchange with routing key
      def self.publish_topic(exchange_name, routing_key, message)
        connection = Bunny.new(hostname: ENV.fetch("RABBITMQ_HOST", "localhost"))
        connection.start

        channel = connection.create_channel
        exchange = channel.topic(exchange_name, durable: true)
        exchange.publish(message, routing_key: routing_key, persistent: true)

        Rails.logger.info "Published message to topic exchange '#{exchange_name}' with routing key '#{routing_key}': #{message}"

        connection.close
      end

      # Publish to a direct exchange with a routing key (routing pattern)
      def self.publish_direct(exchange_name, routing_key, message)
        connection = Bunny.new(hostname: ENV.fetch("RABBITMQ_HOST", "localhost"))
        connection.start

        channel = connection.create_channel
        exchange = channel.direct(exchange_name, durable: true)
        exchange.publish(message, routing_key: routing_key, persistent: true)

        Rails.logger.info "Published message to direct exchange '#{exchange_name}' with routing key '#{routing_key}': #{message}"

        connection.close
      end

      # Publish to a headers exchange. `headers_hash` should include header key/values
      # and may include 'x-match' => 'all' or 'any' when binding subscribers.
      def self.publish_headers(exchange_name, headers_hash, message)
        connection = Bunny.new(hostname: ENV.fetch("RABBITMQ_HOST", "localhost"))
        connection.start

        channel = connection.create_channel
        exchange = channel.headers(exchange_name, durable: true)
        exchange.publish(message, headers: headers_hash, persistent: true)

        Rails.logger.info "Published message to headers exchange '#{exchange_name}' with headers #{headers_hash}: #{message}"

        connection.close
      end
    end
  end
end
