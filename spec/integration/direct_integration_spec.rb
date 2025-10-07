require 'rails_helper'

RSpec.describe 'Direct Exchange integration', type: :integration do
  it 'routes messages to exact routing key matches only' do
    exchange = "integration_test_direct_#{SecureRandom.hex(4)}"
    error_message = "direct_error_#{SecureRandom.hex(4)}"
    warning_message = "direct_warning_#{SecureRandom.hex(4)}"

    Bunny.run(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost')) do |conn|
      channel = conn.create_channel
      exchange_obj = channel.direct(exchange, durable: true)

      # Create queues for different routing keys
      error_queue = channel.queue('', exclusive: true)
      warning_queue = channel.queue('', exclusive: true)

      # Bind queues with exact routing keys
      error_queue.bind(exchange_obj, routing_key: 'error')
      warning_queue.bind(exchange_obj, routing_key: 'warning')

      # Publish messages with specific routing keys
      Rabbitmq::Exchange::Publisher.publish_direct(exchange, 'error', error_message)
      Rabbitmq::Exchange::Publisher.publish_direct(exchange, 'warning', warning_message)

      # Wait for message routing
      sleep 0.1

      # Check exact routing
      received_error = error_queue.pop[2]
      received_warning = warning_queue.pop[2]

      expect(received_error).to eq(error_message)
      expect(received_warning).to eq(warning_message)

      # Verify no cross-contamination
      no_extra_error = error_queue.pop[2]
      no_extra_warning = warning_queue.pop[2]

      expect(no_extra_error).to be_nil
      expect(no_extra_warning).to be_nil
    end
  end
end
