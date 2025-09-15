require 'rails_helper'

describe RabbitmqProducer do
  describe '.publish' do
    let(:queue_name) { 'test_queue' }
    let(:message) { 'test message' }

    it 'publishes a message to RabbitMQ' do
      # Use Bunny to connect and check the message is published
      Bunny.run(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost')) do |conn|
        channel = conn.create_channel
        queue = channel.queue(queue_name, durable: true)
        queue.purge # Clean queue before test
      end

      expect {
        described_class.publish(queue_name, message)
      }.not_to raise_error

      # Check the message is in the queue
      Bunny.run(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost')) do |conn|
        channel = conn.create_channel
        queue = channel.queue(queue_name, durable: true)
        delivery_info, _properties, payload = queue.pop
        expect(payload).to eq(message)
      end
    end
  end
end

