# frozen_string_literal: true

require "bunny"

module Rabbitmq
  module Queue
    class Publisher
      # Publish to a durable queue (used by tests expecting durable queue)
      def self.publish(queue_name, message)
        connection = Bunny.new(hostname: ENV.fetch("RABBITMQ_HOST", "localhost"))
        connection.start

        channel = connection.create_channel
        queue = channel.queue(queue_name, durable: true)
        queue.publish(message, persistent: true)

        Rails.logger.info "Published message to queue '#{queue_name}' via Rabbitmq::Queue::Publisher: #{message}"

        connection.close
      end
    end
  end
end
