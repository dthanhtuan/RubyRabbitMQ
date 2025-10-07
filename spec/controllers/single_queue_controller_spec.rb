require 'rails_helper'

RSpec.describe SingleQueueController, type: :controller do
  describe 'POST #enqueue' do
    let(:test_message) { 'Test message from spec' }

    before do
      allow(Rabbitmq::Queue::Publisher).to receive(:publish)
    end

    it 'publishes message to the demo queue' do
      post :enqueue, params: { message: test_message }

      expect(Rabbitmq::Queue::Publisher).to have_received(:publish)
        .with(SingleQueueController::DEMO_QUEUE, test_message)
    end

    it 'returns success response with message details' do
      post :enqueue, params: { message: test_message }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Message enqueued to single queue')
      expect(json_response['message']).to eq(test_message)
      expect(json_response['queue']).to eq(SingleQueueController::DEMO_QUEUE)
      expect(json_response['pattern']).to eq('Single Queue - one producer and one consumer')
    end

    it 'uses default message when none provided' do
      freeze_time = Time.zone.parse('2023-01-01 12:00:00')
      allow(Time).to receive(:now).and_return(freeze_time)

      post :enqueue

      expected_message = "Single queue message from Rails at #{freeze_time}"
      expect(Rabbitmq::Queue::Publisher).to have_received(:publish)
        .with(SingleQueueController::DEMO_QUEUE, expected_message)

      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq(expected_message)
    end
  end

  describe 'POST #start_consumer' do
    let(:consumer_name) { 'test_consumer_123' }
    let(:mock_job) { instance_double(Rabbitmq::Queue::WorkQueueJob) }

    before do
      allow(Rabbitmq::Queue::WorkQueueJob).to receive(:new).and_return(mock_job)
      allow(mock_job).to receive(:perform)
      allow(Thread).to receive(:new).and_yield
      allow(Rails.logger).to receive(:info)
    end

    it 'starts a background thread with the job' do
      post :start_consumer, params: { consumer_name: consumer_name }

      expect(Thread).to have_received(:new)
      expect(Rabbitmq::Queue::WorkQueueJob).to have_received(:new)
      expect(mock_job).to have_received(:perform).with(SingleQueueController::DEMO_QUEUE)
    end

    it 'logs consumer startup' do
      post :start_consumer, params: { consumer_name: consumer_name }

      expect(Rails.logger).to have_received(:info)
        .with("Starting single queue consumer: #{consumer_name}")
    end

    it 'returns success response with consumer details' do
      post :start_consumer, params: { consumer_name: consumer_name }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Single queue consumer started')
      expect(json_response['consumer_name']).to eq(consumer_name)
      expect(json_response['queue']).to eq(SingleQueueController::DEMO_QUEUE)
      expect(json_response['note']).to eq('Consumer is running in background thread')
    end

    it 'generates random consumer name when none provided' do
      allow(SecureRandom).to receive(:hex).with(4).and_return('abcd1234')

      post :start_consumer

      expected_consumer_name = 'consumer_abcd1234'
      json_response = JSON.parse(response.body)
      expect(json_response['consumer_name']).to eq(expected_consumer_name)
    end
  end
end
