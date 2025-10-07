require 'rails_helper'

RSpec.describe Rabbitmq::Exchange::Subscriber do
  let(:exchange_name) { 'test_exchange' }
  let(:subscriber_name) { 'test_subscriber' }
  let(:mock_connection) { instance_double(Bunny::Session) }
  let(:mock_channel) { instance_double(Bunny::Channel) }
  let(:mock_exchange) { instance_double(Bunny::Exchange) }
  let(:mock_queue) { instance_double(Bunny::Queue) }

  before do
    allow(Bunny).to receive(:new).and_return(mock_connection)
    allow(mock_connection).to receive(:start)
    allow(mock_connection).to receive(:close)
    allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
    allow(mock_queue).to receive(:bind)
    allow(mock_queue).to receive(:subscribe).and_yield(double, double, 'test message')
    allow(Rails.logger).to receive(:info)
    allow(described_class).to receive(:process_message)
  end

  describe '.subscribe_to_exchange' do
    before do
      allow(mock_channel).to receive(:fanout).and_return(mock_exchange)
      allow(mock_channel).to receive(:queue).and_return(mock_queue)
    end

    it 'creates a fanout exchange and binds queue' do
      allow(mock_queue).to receive(:subscribe) # Prevent blocking

      described_class.subscribe_to_exchange(exchange_name, subscriber_name)

      expect(mock_channel).to have_received(:fanout).with(exchange_name, durable: true)
      expect(mock_channel).to have_received(:queue)
        .with("#{exchange_name}.#{subscriber_name}", exclusive: false, auto_delete: true)
      expect(mock_queue).to have_received(:bind).with(mock_exchange)
    end

    it 'logs subscriber connection' do
      allow(mock_queue).to receive(:subscribe)

      described_class.subscribe_to_exchange(exchange_name, subscriber_name)

      expect(Rails.logger).to have_received(:info)
        .with("Exchange subscriber '#{subscriber_name}' connected to exchange '#{exchange_name}'")
    end

    it 'processes received messages with default handler' do
      described_class.subscribe_to_exchange(exchange_name, subscriber_name)

      expect(described_class).to have_received(:process_message).with(subscriber_name, 'test message')
    end
  end

  describe '.subscribe_to_topic' do
    let(:routing_pattern) { 'logs.*' }

    before do
      allow(mock_channel).to receive(:topic).and_return(mock_exchange)
      allow(mock_channel).to receive(:queue).and_return(mock_queue)
    end

    it 'creates a topic exchange and binds queue with routing pattern' do
      allow(mock_queue).to receive(:subscribe)

      described_class.subscribe_to_topic(exchange_name, routing_pattern, subscriber_name)

      expect(mock_channel).to have_received(:topic).with(exchange_name, durable: true)
      expect(mock_queue).to have_received(:bind).with(mock_exchange, routing_key: routing_pattern)
    end

    it 'logs topic subscriber connection' do
      allow(mock_queue).to receive(:subscribe)

      described_class.subscribe_to_topic(exchange_name, routing_pattern, subscriber_name)

      expect(Rails.logger).to have_received(:info)
        .with("Topic subscriber '#{subscriber_name}' connected to topic exchange '#{exchange_name}' with pattern '#{routing_pattern}'")
    end
  end

  describe '.subscribe_to_direct' do
    let(:routing_key) { 'error' }

    before do
      allow(mock_channel).to receive(:direct).and_return(mock_exchange)
      allow(mock_channel).to receive(:queue).and_return(mock_queue)
    end

    it 'creates a direct exchange and binds queue with routing key' do
      allow(mock_queue).to receive(:subscribe)

      described_class.subscribe_to_direct(exchange_name, routing_key, subscriber_name)

      expect(mock_channel).to have_received(:direct).with(exchange_name, durable: true)
      expect(mock_queue).to have_received(:bind).with(mock_exchange, routing_key: routing_key)
    end

    it 'logs direct subscriber connection' do
      allow(mock_queue).to receive(:subscribe)

      described_class.subscribe_to_direct(exchange_name, routing_key, subscriber_name)

      expect(Rails.logger).to have_received(:info)
        .with("Direct subscriber '#{subscriber_name}' connected to direct exchange '#{exchange_name}' with routing key '#{routing_key}'")
    end
  end

  describe '.subscribe_to_headers' do
    let(:headers_hash) { { 'x-match' => 'all', 'type' => 'report' } }

    before do
      allow(mock_channel).to receive(:headers).and_return(mock_exchange)
      allow(mock_channel).to receive(:queue).and_return(mock_queue)
    end

    it 'creates a headers exchange and binds queue with headers arguments' do
      allow(mock_queue).to receive(:subscribe)

      described_class.subscribe_to_headers(exchange_name, headers_hash, subscriber_name)

      expect(mock_channel).to have_received(:headers).with(exchange_name, durable: true)
      expect(mock_queue).to have_received(:bind).with(mock_exchange, arguments: headers_hash)
    end

    it 'logs headers subscriber connection' do
      allow(mock_queue).to receive(:subscribe)

      described_class.subscribe_to_headers(exchange_name, headers_hash, subscriber_name)

      expect(Rails.logger).to have_received(:info)
        .with("Headers subscriber '#{subscriber_name}' connected to headers exchange '#{exchange_name}' with headers #{headers_hash.inspect}")
    end
  end

  describe '.process_message' do
    let(:message) { 'test message' }
    let(:routing_key) { 'test.routing' }

    # We need to test the actual method since it's a private class method
    # We'll use a different approach - test the behavior through public methods
    it 'is called during message processing' do
      allow(mock_channel).to receive(:fanout).and_return(mock_exchange)
      allow(mock_channel).to receive(:queue).and_return(mock_queue)

      # Reset the mock to check actual calls
      allow(described_class).to receive(:process_message).and_call_original

      described_class.subscribe_to_exchange(exchange_name, subscriber_name)

      expect(described_class).to have_received(:process_message).with(subscriber_name, 'test message')
    end
  end
end
