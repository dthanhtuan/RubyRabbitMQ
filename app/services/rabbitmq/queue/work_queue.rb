# frozen_string_literal: true

require 'bunny'

module Rabbitmq
  module Queue
    class WorkQueue
      # Send message to a specific queue for work distribution
      def self.enqueue(queue_name, message)
        connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
        connection.start

        channel = connection.create_channel
        channel.prefetch(1) # Process one message at a time per consumer
        queue = channel.queue(queue_name, durable: true)
        queue.publish(message, persistent: true)

        Rails.logger.info "Enqueued work to queue '#{queue_name}': #{message}"

        connection.close
      end
    end
  end
end

