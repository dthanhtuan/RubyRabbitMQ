require 'rails_helper'

RSpec.describe 'Work Queue integration', type: :integration do
  it 'distributes messages among multiple consumers' do
    queue_name = "integration_work_queue_#{SecureRandom.hex(4)}"
    messages = Array.new(6) { |i| "msg#{i}_#{SecureRandom.hex(4)}" }

    Bunny.run(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost')) do |conn|
      channel = conn.create_channel
      # Match application queue declaration (durable: true)
      q1 = channel.queue(queue_name, durable: true)
      channel.queue(queue_name, durable: true)

      # Ensure queue is empty before test
      q1.purge

      # Publish messages using the application's helper
      messages.each { |m| Rabbitmq::Queue::Publisher.publish(queue_name, m) }

      received1 = []
      received2 = []

      # Simulate two consumers by popping from the same queue using two channels
      ch_a = conn.create_channel
      ch_b = conn.create_channel
      # Consumer channels must declare the queue with the same durability as the producer
      qa = ch_a.queue(queue_name, durable: true)
      qb = ch_b.queue(queue_name, durable: true)

      while (received1.size + received2.size) < messages.size
        d1 = qa.pop
        received1 << d1[2] if d1 && d1[2]

        d2 = qb.pop
        received2 << d2[2] if d2 && d2[2]

        sleep 0.01
      end

      total_received = (received1 + received2).compact
      expect(total_received.sort).to match_array(messages.sort)
      expect(received1.compact).not_to be_empty
      expect(received2.compact).not_to be_empty
    end
  end
end
