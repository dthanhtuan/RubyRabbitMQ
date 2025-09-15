# app/jobs/rabbitmq_consumer_job.rb
require 'bunny'

class RabbitmqConsumerJob < ApplicationJob
  queue_as :default

  def perform(queue_name)
    connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
    connection.start
    channel = connection.create_channel
    queue = channel.queue(queue_name, durable: true)
    begin
      queue.subscribe(block: true) do |_delivery_info, _properties, body|
        Rails.logger.info "Consumed message: #{body}"
        # Add your message processing logic here
      end
    ensure
      connection.close
    end
  end
end
