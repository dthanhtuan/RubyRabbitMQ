require 'rails_helper'

RSpec.describe 'Topic Exchange integration', type: :integration do
  it 'routes messages based on routing key patterns' do
    exchange = "integration_test_topic_#{SecureRandom.hex(4)}"
    message1 = "error_message_#{SecureRandom.hex(4)}"
    message2 = "info_message_#{SecureRandom.hex(4)}"

    Bunny.run(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost')) do |conn|
      channel = conn.create_channel
      exchange_obj = channel.topic(exchange, durable: true)

      # Create queues for different routing patterns
      error_queue = channel.queue('', exclusive: true)
      all_logs_queue = channel.queue('', exclusive: true)
      info_queue = channel.queue('', exclusive: true)

      # Bind queues with different routing patterns
      error_queue.bind(exchange_obj, routing_key: 'logs.error')
      all_logs_queue.bind(exchange_obj, routing_key: 'logs.*')
      info_queue.bind(exchange_obj, routing_key: 'logs.info')

      # Publish messages with different routing keys
      Rabbitmq::Exchange::Publisher.publish_topic(exchange, 'logs.error', message1)
      Rabbitmq::Exchange::Publisher.publish_topic(exchange, 'logs.info', message2)

      # Wait for message routing
      sleep 0.1

      # Check message distribution
      error_msg = error_queue.pop[2]
      all_logs_error = all_logs_queue.pop[2]
      all_logs_info = all_logs_queue.pop[2]
      info_msg = info_queue.pop[2]

      expect(error_msg).to eq(message1)
      expect([all_logs_error, all_logs_info]).to contain_exactly(message1, message2)
      expect(info_msg).to eq(message2)
    end
  end
end
