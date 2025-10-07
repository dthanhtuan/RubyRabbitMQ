require 'rails_helper'

RSpec.describe 'Pub/Sub (fanout) integration', type: :integration do
  it 'delivers the same message to multiple subscribers' do
    exchange = "integration_test_fanout_#{SecureRandom.hex(4)}"
    message = "hello_fanout_#{SecureRandom.hex(4)}"

    Bunny.run(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost')) do |conn|
      channel = conn.create_channel
      # Match application exchange declaration (durable: true)
      exchange_obj = channel.fanout(exchange, durable: true)

      q1 = channel.queue('', exclusive: true)
      q2 = channel.queue('', exclusive: true)

      q1.bind(exchange_obj)
      q2.bind(exchange_obj)

      # Publish using the application's helper (opens its own connection)
      Rabbitmq::Exchange::Publisher.broadcast(exchange, message)

      # Wait a short time for the message to be routed
      payload1 = nil
      payload2 = nil

      20.times do
        delivery1 = q1.pop
        delivery2 = q2.pop
        payload1 = delivery1[2] if delivery1 && delivery1[2]
        payload2 = delivery2[2] if delivery2 && delivery2[2]
        break if payload1 && payload2
        sleep 0.05
      end

      expect(payload1).to eq(message)
      expect(payload2).to eq(message)
    end
  end
end
