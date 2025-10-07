require 'rails_helper'

RSpec.describe PubSub::DirectController, type: :controller do
  describe 'POST #publish' do
    let(:test_message) { 'Test direct message' }
    let(:routing_key) { 'error' }

    before do
      allow(Rabbitmq::Exchange::Publisher).to receive(:publish_direct)
    end

    it 'publishes message to direct exchange with routing key' do
      post :publish, params: { message: test_message, routing_key: routing_key }

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_direct)
        .with(PubSub::DirectController::DEMO_DIRECT_EXCHANGE, routing_key, test_message)
    end

    it 'returns success response with direct exchange details' do
      post :publish, params: { message: test_message, routing_key: routing_key }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Message published to direct exchange')
      expect(json_response['message']).to eq(test_message)
      expect(json_response['exchange']).to eq(PubSub::DirectController::DEMO_DIRECT_EXCHANGE)
      expect(json_response['routing_key']).to eq(routing_key)
      expect(json_response['pattern']).to eq('Direct - messages routed by exact routing key')
    end

    it 'uses default values when none provided' do
      freeze_time = Time.zone.parse('2023-01-01 12:00:00')
      allow(Time).to receive(:now).and_return(freeze_time)

      post :publish

      expected_message = "Direct message from Rails at #{freeze_time}"
      default_routing_key = 'info'

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_direct)
        .with(PubSub::DirectController::DEMO_DIRECT_EXCHANGE, default_routing_key, expected_message)

      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq(expected_message)
      expect(json_response['routing_key']).to eq(default_routing_key)
    end
  end

  describe 'POST #start_subscriber' do
    let(:subscriber_name) { 'test_direct_subscriber' }
    let(:routing_key) { 'error' }

    before do
      allow(Rabbitmq::Exchange::Subscriber).to receive(:subscribe_to_direct)
      allow(Thread).to receive(:new).and_yield
    end

    it 'starts a background thread with direct subscriber' do
      post :start_subscriber, params: { subscriber_name: subscriber_name, routing_key: routing_key }

      expect(Thread).to have_received(:new)
      expect(Rabbitmq::Exchange::Subscriber).to have_received(:subscribe_to_direct)
        .with(PubSub::DirectController::DEMO_DIRECT_EXCHANGE, routing_key, subscriber_name)
    end

    it 'returns success response with direct subscriber details' do
      post :start_subscriber, params: { subscriber_name: subscriber_name, routing_key: routing_key }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Direct subscriber started')
      expect(json_response['subscriber_name']).to eq(subscriber_name)
      expect(json_response['exchange']).to eq(PubSub::DirectController::DEMO_DIRECT_EXCHANGE)
      expect(json_response['routing_key']).to eq(routing_key)
      expect(json_response['note']).to eq('Direct subscriber is running in background thread')
    end

    it 'uses default values when none provided' do
      allow(SecureRandom).to receive(:hex).with(4).and_return('abc123')

      post :start_subscriber

      expected_subscriber_name = 'direct_subscriber_abc123'
      default_routing_key = 'info'

      json_response = JSON.parse(response.body)
      expect(json_response['subscriber_name']).to eq(expected_subscriber_name)
      expect(json_response['routing_key']).to eq(default_routing_key)
    end
  end
end
