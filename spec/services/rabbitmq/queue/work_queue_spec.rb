require 'rails_helper'

RSpec.describe Rabbitmq::Queue::WorkQueue do
  describe '.enqueue' do
    let(:queue_name) { 'test_work_queue' }
    let(:message) { 'test work message' }
    let(:mock_connection) { instance_double(Bunny::Session) }
    let(:mock_channel) { instance_double(Bunny::Channel) }
    let(:mock_queue) { instance_double(Bunny::Queue) }

    before do
      allow(Bunny).to receive(:new).and_return(mock_connection)
      allow(mock_connection).to receive(:start)
      allow(mock_connection).to receive(:close)
      allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
      allow(mock_channel).to receive(:prefetch)
      allow(mock_channel).to receive(:queue).and_return(mock_queue)
      allow(mock_queue).to receive(:publish)
      allow(Rails.logger).to receive(:info)
    end

    it 'creates a connection to RabbitMQ' do
      described_class.enqueue(queue_name, message)

      expect(Bunny).to have_received(:new).with(hostname: 'localhost')
      expect(mock_connection).to have_received(:start)
    end

    it 'creates a durable queue with prefetch configuration' do
      described_class.enqueue(queue_name, message)

      expect(mock_channel).to have_received(:prefetch).with(1)
      expect(mock_channel).to have_received(:queue).with(queue_name, durable: true)
    end

    it 'publishes message with persistence' do
      described_class.enqueue(queue_name, message)

      expect(mock_queue).to have_received(:publish).with(message, persistent: true)
    end

    it 'logs the enqueue operation' do
      described_class.enqueue(queue_name, message)

      expect(Rails.logger).to have_received(:info).with("Enqueued work to queue '#{queue_name}': #{message}")
    end

    it 'closes the connection after publishing' do
      described_class.enqueue(queue_name, message)

      expect(mock_connection).to have_received(:close)
    end

    context 'when RABBITMQ_HOST environment variable is set' do
      before do
        ENV['RABBITMQ_HOST'] = 'custom-host'
      end

      after do
        ENV.delete('RABBITMQ_HOST')
      end

      it 'uses the custom hostname' do
        described_class.enqueue(queue_name, message)

        expect(Bunny).to have_received(:new).with(hostname: 'custom-host')
      end
    end
  end
end
