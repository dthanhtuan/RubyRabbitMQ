# frozen_string_literal: true

require 'bunny'

class RabbitmqProducer
  def self.publish(queue_name, message)
    connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
    connection.start
    channel = connection.create_channel
    queue = channel.queue(queue_name, durable: true)
    queue.publish(message, persistent: true)
    connection.close
  end
end

