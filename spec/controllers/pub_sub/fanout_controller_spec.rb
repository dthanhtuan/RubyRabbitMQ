require 'rails_helper'

RSpec.describe PubSub::FanoutController, type: :controller do
  describe 'POST #broadcast' do
    let(:test_message) { 'Test broadcast message' }

    before do
      allow(Rabbitmq::Exchange::Publisher).to receive(:broadcast)
    end

    it 'broadcasts message to the demo exchange' do
      post :broadcast, params: { message: test_message }

      expect(Rabbitmq::Exchange::Publisher).to have_received(:broadcast)
        .with(PubSub::FanoutController::DEMO_EXCHANGE, test_message)
    end

    it 'returns success response with broadcast details' do
      post :broadcast, params: { message: test_message }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Message broadcasted')
      expect(json_response['message']).to eq(test_message)
      expect(json_response['exchange']).to eq(PubSub::FanoutController::DEMO_EXCHANGE)
      expect(json_response['pattern']).to eq('Fanout - all subscribers receive this message')
    end

    it 'uses default message when none provided' do
      freeze_time = Time.zone.parse('2023-01-01 12:00:00')
      allow(Time).to receive(:now).and_return(freeze_time)

      post :broadcast

      expected_message = "Broadcast message from Rails at #{freeze_time}"
      expect(Rabbitmq::Exchange::Publisher).to have_received(:broadcast)
        .with(PubSub::FanoutController::DEMO_EXCHANGE, expected_message)

      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq(expected_message)
    end
  end

  describe 'POST #start_subscriber' do
    let(:subscriber_name) { 'test_subscriber_123' }

    before do
      allow(Rabbitmq::Exchange::Subscriber).to receive(:subscribe_to_exchange)
      allow(Thread).to receive(:new).and_yield
    end

    it 'starts a background thread with the subscriber' do
      post :start_subscriber, params: { subscriber_name: subscriber_name }

      expect(Thread).to have_received(:new)
      expect(Rabbitmq::Exchange::Subscriber).to have_received(:subscribe_to_exchange)
        .with(PubSub::FanoutController::DEMO_EXCHANGE, subscriber_name)
    end

    it 'returns success response with subscriber details' do
      post :start_subscriber, params: { subscriber_name: subscriber_name }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Subscriber started')
      expect(json_response['subscriber_name']).to eq(subscriber_name)
      expect(json_response['exchange']).to eq(PubSub::FanoutController::DEMO_EXCHANGE)
      expect(json_response['note']).to eq('Subscriber is running in background thread')
    end

    it 'generates random subscriber name when none provided' do
      allow(SecureRandom).to receive(:hex).with(4).and_return('abcd1234')

      post :start_subscriber

      expected_subscriber_name = 'subscriber_abcd1234'
      json_response = JSON.parse(response.body)
      expect(json_response['subscriber_name']).to eq(expected_subscriber_name)
    end
  end
end
