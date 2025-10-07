require 'rails_helper'

RSpec.describe PubSub::TopicController, type: :controller do
  describe 'POST #publish' do
    let(:test_message) { 'Test topic message' }
    let(:routing_key) { 'logs.error' }

    before do
      allow(Rabbitmq::Exchange::Publisher).to receive(:publish_topic)
    end

    it 'publishes message to topic exchange with routing key' do
      post :publish, params: { message: test_message, routing_key: routing_key }

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_topic)
        .with(PubSub::TopicController::DEMO_TOPIC_EXCHANGE, routing_key, test_message)
    end

    it 'returns success response with topic details' do
      post :publish, params: { message: test_message, routing_key: routing_key }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Message published to topic')
      expect(json_response['message']).to eq(test_message)
      expect(json_response['exchange']).to eq(PubSub::TopicController::DEMO_TOPIC_EXCHANGE)
      expect(json_response['routing_key']).to eq(routing_key)
      expect(json_response['pattern']).to eq('Topic - subscribers with matching patterns receive this message')
    end

    it 'uses default values when none provided' do
      freeze_time = Time.zone.parse('2023-01-01 12:00:00')
      allow(Time).to receive(:now).and_return(freeze_time)

      post :publish

      expected_message = "Topic message from Rails at #{freeze_time}"
      default_routing_key = 'general.info'

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_topic)
        .with(PubSub::TopicController::DEMO_TOPIC_EXCHANGE, default_routing_key, expected_message)

      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq(expected_message)
      expect(json_response['routing_key']).to eq(default_routing_key)
    end
  end

  describe 'POST #start_subscriber' do
    let(:subscriber_name) { 'test_topic_subscriber' }
    let(:routing_pattern) { 'logs.*' }

    before do
      allow(Rabbitmq::Exchange::Subscriber).to receive(:subscribe_to_topic)
      allow(Thread).to receive(:new).and_yield
    end

    it 'starts a background thread with topic subscriber' do
      post :start_subscriber, params: { subscriber_name: subscriber_name, routing_pattern: routing_pattern }

      expect(Thread).to have_received(:new)
      expect(Rabbitmq::Exchange::Subscriber).to have_received(:subscribe_to_topic)
        .with(PubSub::TopicController::DEMO_TOPIC_EXCHANGE, routing_pattern, subscriber_name)
    end

    it 'returns success response with topic subscriber details' do
      post :start_subscriber, params: { subscriber_name: subscriber_name, routing_pattern: routing_pattern }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Topic subscriber started')
      expect(json_response['subscriber_name']).to eq(subscriber_name)
      expect(json_response['exchange']).to eq(PubSub::TopicController::DEMO_TOPIC_EXCHANGE)
      expect(json_response['routing_pattern']).to eq(routing_pattern)
      expect(json_response['note']).to eq('Topic subscriber is running in background thread')
    end

    it 'uses default values when none provided' do
      allow(SecureRandom).to receive(:hex).with(4).and_return('xyz789')

      post :start_subscriber

      expected_subscriber_name = 'topic_subscriber_xyz789'
      default_pattern = '#'

      json_response = JSON.parse(response.body)
      expect(json_response['subscriber_name']).to eq(expected_subscriber_name)
      expect(json_response['routing_pattern']).to eq(default_pattern)
    end
  end
end
