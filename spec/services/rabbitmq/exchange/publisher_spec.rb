require 'rails_helper'

RSpec.describe Rabbitmq::Exchange::Publisher do
  let(:exchange_name) { 'test_exchange' }
  let(:message) { 'test message' }
  let(:mock_connection) { instance_double(Bunny::Session) }
  let(:mock_channel) { instance_double(Bunny::Channel) }
  let(:mock_exchange) { instance_double(Bunny::Exchange) }

  before do
    allow(Bunny).to receive(:new).and_return(mock_connection)
    allow(mock_connection).to receive(:start)
    allow(mock_connection).to receive(:close)
    allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
    allow(mock_exchange).to receive(:publish)
    allow(Rails.logger).to receive(:info)
  end

  describe '.broadcast' do
    before do
      allow(mock_channel).to receive(:fanout).and_return(mock_exchange)
    end

    it 'creates a fanout exchange and publishes message' do
      described_class.broadcast(exchange_name, message)

      expect(mock_channel).to have_received(:fanout).with(exchange_name, durable: true)
      expect(mock_exchange).to have_received(:publish).with(message, persistent: true)
    end

    it 'logs the broadcast operation' do
      described_class.broadcast(exchange_name, message)

      expect(Rails.logger).to have_received(:info).with("Broadcasted message to exchange '#{exchange_name}': #{message}")
    end
  end

  describe '.publish_topic' do
    let(:routing_key) { 'test.routing.key' }

    before do
      allow(mock_channel).to receive(:topic).and_return(mock_exchange)
    end

    it 'creates a topic exchange and publishes message with routing key' do
      described_class.publish_topic(exchange_name, routing_key, message)

      expect(mock_channel).to have_received(:topic).with(exchange_name, durable: true)
      expect(mock_exchange).to have_received(:publish).with(message, routing_key: routing_key, persistent: true)
    end

    it 'logs the topic publish operation' do
      described_class.publish_topic(exchange_name, routing_key, message)

      expect(Rails.logger).to have_received(:info)
        .with("Published message to topic exchange '#{exchange_name}' with routing key '#{routing_key}': #{message}")
    end
  end

  describe '.publish_direct' do
    let(:routing_key) { 'direct_routing_key' }

    before do
      allow(mock_channel).to receive(:direct).and_return(mock_exchange)
    end

    it 'creates a direct exchange and publishes message with routing key' do
      described_class.publish_direct(exchange_name, routing_key, message)

      expect(mock_channel).to have_received(:direct).with(exchange_name, durable: true)
      expect(mock_exchange).to have_received(:publish).with(message, routing_key: routing_key, persistent: true)
    end

    it 'logs the direct publish operation' do
      described_class.publish_direct(exchange_name, routing_key, message)

      expect(Rails.logger).to have_received(:info)
        .with("Published message to direct exchange '#{exchange_name}' with routing key '#{routing_key}': #{message}")
    end
  end

  describe '.publish_headers' do
    let(:headers_hash) { { 'type' => 'report', 'format' => 'json' } }

    before do
      allow(mock_channel).to receive(:headers).and_return(mock_exchange)
    end

    it 'creates a headers exchange and publishes message with headers' do
      described_class.publish_headers(exchange_name, headers_hash, message)

      expect(mock_channel).to have_received(:headers).with(exchange_name, durable: true)
      expect(mock_exchange).to have_received(:publish).with(message, headers: headers_hash, persistent: true)
    end

    it 'logs the headers publish operation' do
      described_class.publish_headers(exchange_name, headers_hash, message)

      expect(Rails.logger).to have_received(:info)
        .with("Published message to headers exchange '#{exchange_name}' with headers #{headers_hash}: #{message}")
    end
  end

  shared_examples 'connection management' do |method_name, *args|
    before do
      # Set up the appropriate exchange method mock
      case method_name
      when :broadcast
        allow(mock_channel).to receive(:fanout).and_return(mock_exchange)
      when :publish_topic
        allow(mock_channel).to receive(:topic).and_return(mock_exchange)
      when :publish_direct
        allow(mock_channel).to receive(:direct).and_return(mock_exchange)
      when :publish_headers
        allow(mock_channel).to receive(:headers).and_return(mock_exchange)
      end
    end

    it 'creates connection and closes it after publishing' do
      described_class.public_send(method_name, *args)

      expect(Bunny).to have_received(:new).with(hostname: 'localhost')
      expect(mock_connection).to have_received(:start)
      expect(mock_connection).to have_received(:close)
    end
  end

  include_examples 'connection management', :broadcast, 'test_exchange', 'test message'
  include_examples 'connection management', :publish_topic, 'test_exchange', 'routing.key', 'test message'
  include_examples 'connection management', :publish_direct, 'test_exchange', 'routing_key', 'test message'
  include_examples 'connection management', :publish_headers, 'test_exchange', { type: 'test' }, 'test message'
end
