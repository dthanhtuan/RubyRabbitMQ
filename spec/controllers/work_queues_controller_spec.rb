require 'rails_helper'

RSpec.describe WorkQueuesController, type: :controller do
  describe 'POST #enqueue' do
    let(:test_message) { 'Test work task from spec' }

    before do
      allow(Rabbitmq::Queue::WorkQueue).to receive(:enqueue)
    end

    it 'enqueues work task to the demo queue' do
      post :enqueue, params: { message: test_message }

      expect(Rabbitmq::Queue::WorkQueue).to have_received(:enqueue)
        .with(WorkQueuesController::DEMO_QUEUE, test_message)
    end

    it 'returns success response with work details' do
      post :enqueue, params: { message: test_message }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Work enqueued')
      expect(json_response['message']).to eq(test_message)
      expect(json_response['queue']).to eq(WorkQueuesController::DEMO_QUEUE)
      expect(json_response['pattern']).to eq('Work Queue - one worker will process this task')
    end

    it 'uses default message when none provided' do
      freeze_time = Time.zone.parse('2023-01-01 12:00:00')
      allow(Time).to receive(:now).and_return(freeze_time)

      post :enqueue

      expected_message = "Work task from Rails at #{freeze_time}"
      expect(Rabbitmq::Queue::WorkQueue).to have_received(:enqueue)
        .with(WorkQueuesController::DEMO_QUEUE, expected_message)

      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq(expected_message)
    end
  end

  describe 'POST #start_worker' do
    let(:worker_name) { 'test_worker_456' }
    let(:mock_job) { instance_double(Rabbitmq::Queue::WorkQueueJob) }

    before do
      allow(Rabbitmq::Queue::WorkQueueJob).to receive(:new).and_return(mock_job)
      allow(mock_job).to receive(:perform)
      allow(Thread).to receive(:new).and_yield
      allow(Rails.logger).to receive(:info)
    end

    it 'starts a background thread with the work queue job' do
      post :start_worker, params: { worker_name: worker_name }

      expect(Thread).to have_received(:new)
      expect(Rabbitmq::Queue::WorkQueueJob).to have_received(:new)
      expect(mock_job).to have_received(:perform).with(WorkQueuesController::DEMO_QUEUE)
    end

    it 'logs worker startup' do
      post :start_worker, params: { worker_name: worker_name }

      expect(Rails.logger).to have_received(:info)
        .with("Starting work queue worker: #{worker_name}")
    end

    it 'returns success response with worker details' do
      post :start_worker, params: { worker_name: worker_name }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Work queue worker started')
      expect(json_response['worker_name']).to eq(worker_name)
      expect(json_response['queue']).to eq(WorkQueuesController::DEMO_QUEUE)
      expect(json_response['note']).to eq('Worker is running in background thread')
    end

    it 'generates random worker name when none provided' do
      allow(SecureRandom).to receive(:hex).with(4).and_return('xyz789')

      post :start_worker

      expected_worker_name = 'worker_xyz789'
      json_response = JSON.parse(response.body)
      expect(json_response['worker_name']).to eq(expected_worker_name)
    end
  end
end
