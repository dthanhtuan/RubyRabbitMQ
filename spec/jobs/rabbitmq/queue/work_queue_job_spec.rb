require 'rails_helper'

RSpec.describe Rabbitmq::Queue::WorkQueueJob, type: :job do
  let(:queue_name) { 'test_queue' }
  let(:exchange_name) { 'test_exchange' }
  let(:subscriber_name) { 'test_subscriber' }
  let(:routing_key) { 'test.routing' }
  let(:message) { 'test message' }

  let(:mock_connection) { instance_double(Bunny::Session) }
  let(:mock_channel) { instance_double(Bunny::Channel) }
  let(:mock_queue) { instance_double(Bunny::Queue) }
  let(:mock_delivery_info) { instance_double(Bunny::DeliveryInfo, delivery_tag: 123, routing_key: routing_key) }

  before do
    allow(Bunny).to receive(:new).and_return(mock_connection)
    allow(mock_connection).to receive(:start)
    allow(mock_connection).to receive(:close)
    allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
    allow(mock_channel).to receive(:prefetch)
    allow(mock_channel).to receive(:queue).and_return(mock_queue)
    allow(mock_channel).to receive(:ack)
    allow(mock_channel).to receive(:nack)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    let(:job) { described_class.new }

    before do
      allow(mock_queue).to receive(:subscribe).and_yield(mock_delivery_info, {}, message)
      allow(job).to receive(:process_work)
    end

    it 'creates connection with correct hostname' do
      job.perform(queue_name)

      expect(Bunny).to have_received(:new).with(hostname: 'localhost')
      expect(mock_connection).to have_received(:start)
    end

    it 'sets up channel with prefetch and durable queue' do
      job.perform(queue_name)

      expect(mock_channel).to have_received(:prefetch).with(1)
      expect(mock_channel).to have_received(:queue).with(queue_name, durable: true)
    end

    it 'subscribes to queue with manual acknowledgment' do
      job.perform(queue_name)

      expect(mock_queue).to have_received(:subscribe).with(manual_ack: true, block: true)
    end

    it 'processes work and acknowledges message on success' do
      job.perform(queue_name)

      expect(job).to have_received(:process_work).with(message)
      expect(mock_channel).to have_received(:ack).with(mock_delivery_info.delivery_tag)
      expect(Rails.logger).to have_received(:info).with("Processing work from queue '#{queue_name}': #{message}")
    end

    it 'handles errors and requeues message' do
      allow(job).to receive(:process_work).and_raise(StandardError.new('Processing error'))

      job.perform(queue_name)

      expect(mock_channel).to have_received(:nack).with(mock_delivery_info.delivery_tag, false, true)
      expect(Rails.logger).to have_received(:error).with("Error processing message from '#{queue_name}': Processing error")
    end

    it 'closes connection after processing' do
      job.perform(queue_name)

      expect(mock_connection).to have_received(:close)
    end

    context 'with custom RABBITMQ_HOST' do
      before do
        ENV['RABBITMQ_HOST'] = 'custom-rabbitmq-host'
      end

      after do
        ENV.delete('RABBITMQ_HOST')
      end

      it 'uses custom hostname from environment' do
        job.perform(queue_name)

        expect(Bunny).to have_received(:new).with(hostname: 'custom-rabbitmq-host')
      end
    end
  end

  describe '#perform_subscriber' do
    let(:job) { described_class.new }

    before do
      allow(Rabbitmq::Exchange::Subscriber).to receive(:subscribe_to_exchange).and_yield(mock_delivery_info, {}, message)
      allow(job).to receive(:process_pubsub_message)
    end

    it 'subscribes to exchange and processes messages' do
      job.perform_subscriber(exchange_name, subscriber_name)

      expect(Rabbitmq::Exchange::Subscriber).to have_received(:subscribe_to_exchange)
        .with(exchange_name, subscriber_name)
      expect(job).to have_received(:process_pubsub_message).with(message, subscriber_name)
      expect(Rails.logger).to have_received(:info).with("Subscriber '#{subscriber_name}' processing: #{message}")
    end
  end

  describe '#perform_topic_subscriber' do
    let(:job) { described_class.new }
    let(:routing_pattern) { 'logs.*' }

    before do
      allow(Rabbitmq::Exchange::Subscriber).to receive(:subscribe_to_topic).and_yield(mock_delivery_info, {}, message)
      allow(job).to receive(:process_topic_message)
    end

    it 'subscribes to topic exchange and processes messages with routing info' do
      job.perform_topic_subscriber(exchange_name, routing_pattern, subscriber_name)

      expect(Rabbitmq::Exchange::Subscriber).to have_received(:subscribe_to_topic)
        .with(exchange_name, routing_pattern, subscriber_name)
      expect(job).to have_received(:process_topic_message).with(message, subscriber_name, routing_key)
      expect(Rails.logger).to have_received(:info)
        .with("Topic subscriber '#{subscriber_name}' processing: #{message} (routing: #{routing_key})")
    end
  end

  describe '#perform_direct_subscriber' do
    let(:job) { described_class.new }

    before do
      allow(Rabbitmq::Exchange::Subscriber).to receive(:subscribe_to_direct).and_yield(mock_delivery_info, {}, message)
      allow(job).to receive(:process_topic_message)
    end

    it 'subscribes to direct exchange and processes messages with routing info' do
      job.perform_direct_subscriber(exchange_name, routing_key, subscriber_name)

      expect(Rabbitmq::Exchange::Subscriber).to have_received(:subscribe_to_direct)
        .with(exchange_name, routing_key, subscriber_name)
      expect(job).to have_received(:process_topic_message).with(message, subscriber_name, routing_key)
      expect(Rails.logger).to have_received(:info)
        .with("Direct subscriber '#{subscriber_name}' processing: #{message} (routing: #{routing_key})")
    end
  end

  describe 'private methods' do
    let(:job) { described_class.new }

    describe '#process_work' do
      it 'logs default work processing' do
        job.send(:process_work, message)

        expect(Rails.logger).to have_received(:info).with("Default work processing: #{message}")
      end
    end

    describe '#process_pubsub_message' do
      it 'logs default pubsub processing' do
        job.send(:process_pubsub_message, message, subscriber_name)

        expect(Rails.logger).to have_received(:info).with("Default processing for subscriber #{subscriber_name}: #{message}")
      end
    end

    describe '#process_topic_message' do
      it 'logs default topic processing with routing key' do
        job.send(:process_topic_message, message, subscriber_name, routing_key)

        expect(Rails.logger).to have_received(:info)
          .with("Default topic processing for subscriber #{subscriber_name} (#{routing_key}): #{message}")
      end
    end
  end
end
