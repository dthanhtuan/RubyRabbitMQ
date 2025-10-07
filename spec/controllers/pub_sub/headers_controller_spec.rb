require 'rails_helper'

RSpec.describe PubSub::HeadersController, type: :controller do
  describe 'POST #publish' do
    let(:test_message) { 'Test headers message' }
    let(:headers_hash) { { 'type' => 'report', 'format' => 'json' } }

    before do
      allow(Rabbitmq::Exchange::Publisher).to receive(:publish_headers)
    end

    it 'publishes message to headers exchange with headers hash' do
      post :publish, params: { message: test_message, headers: headers_hash }

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_headers)
        .with(PubSub::HeadersController::DEMO_HEADERS_EXCHANGE, headers_hash, test_message)
    end

    it 'returns success response with headers exchange details' do
      post :publish, params: { message: test_message, headers: headers_hash }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Message published to headers exchange')
      expect(json_response['message']).to eq(test_message)
      expect(json_response['exchange']).to eq(PubSub::HeadersController::DEMO_HEADERS_EXCHANGE)
      expect(json_response['headers']).to eq(headers_hash)
    end

    it 'parses JSON string headers' do
      headers_json = '{"type":"alert","priority":"high"}'
      expected_headers = { 'type' => 'alert', 'priority' => 'high' }

      post :publish, params: { message: test_message, headers: headers_json }

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_headers)
        .with(PubSub::HeadersController::DEMO_HEADERS_EXCHANGE, expected_headers, test_message)
    end

    it 'handles invalid JSON string gracefully' do
      invalid_json = '{"invalid":"json'

      post :publish, params: { message: test_message, headers: invalid_json }

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_headers)
        .with(PubSub::HeadersController::DEMO_HEADERS_EXCHANGE, {}, test_message)
    end

    it 'uses default values when none provided' do
      freeze_time = Time.zone.parse('2023-01-01 12:00:00')
      allow(Time).to receive(:now).and_return(freeze_time)

      post :publish

      expected_message = "Headers message from Rails at #{freeze_time}"

      expect(Rabbitmq::Exchange::Publisher).to have_received(:publish_headers)
        .with(PubSub::HeadersController::DEMO_HEADERS_EXCHANGE, {}, expected_message)

      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq(expected_message)
      expect(json_response['headers']).to eq({})
    end
  end

  describe 'POST #start_subscriber' do
    let(:subscriber_name) { 'test_headers_subscriber' }
    let(:headers_hash) { { 'x-match' => 'all', 'type' => 'report' } }

    before do
      allow(Rabbitmq::Exchange::Subscriber).to receive(:subscribe_to_headers)
      allow(Thread).to receive(:new).and_yield
    end

    it 'starts a background thread with headers subscriber' do
      post :start_subscriber, params: { subscriber_name: subscriber_name, headers: headers_hash }

      expect(Thread).to have_received(:new)
      expect(Rabbitmq::Exchange::Subscriber).to have_received(:subscribe_to_headers)
        .with(PubSub::HeadersController::DEMO_HEADERS_EXCHANGE, headers_hash, subscriber_name)
    end

    it 'returns success response with headers subscriber details' do
      post :start_subscriber, params: { subscriber_name: subscriber_name, headers: headers_hash }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('Headers subscriber started')
      expect(json_response['subscriber_name']).to eq(subscriber_name)
      expect(json_response['exchange']).to eq(PubSub::HeadersController::DEMO_HEADERS_EXCHANGE)
      expect(json_response['bind_headers']).to eq(headers_hash)
      expect(json_response['note']).to eq('Headers subscriber is running in background thread')
    end

    it 'uses default values when none provided' do
      allow(SecureRandom).to receive(:hex).with(4).and_return('def456')

      post :start_subscriber

      expected_subscriber_name = 'headers_subscriber_def456'

      json_response = JSON.parse(response.body)
      expect(json_response['subscriber_name']).to eq(expected_subscriber_name)
      expect(json_response['bind_headers']).to eq({})
    end
  end

  describe '#extract_headers_param' do
    controller_instance = described_class.new

    it 'returns empty hash for blank param' do
      result = controller_instance.send(:extract_headers_param, nil)
      expect(result).to eq({})

      result = controller_instance.send(:extract_headers_param, '')
      expect(result).to eq({})
    end

    it 'parses valid JSON string' do
      json_string = '{"key":"value","number":123}'
      result = controller_instance.send(:extract_headers_param, json_string)
      expect(result).to eq({ 'key' => 'value', 'number' => 123 })
    end

    it 'returns empty hash for invalid JSON string' do
      invalid_json = '{"invalid":'
      result = controller_instance.send(:extract_headers_param, invalid_json)
      expect(result).to eq({})
    end

    it 'converts ActionController::Parameters to hash' do
      params = ActionController::Parameters.new({ 'type' => 'test', 'priority' => 'high' })
      result = controller_instance.send(:extract_headers_param, params)
      expect(result).to eq({ 'type' => 'test', 'priority' => 'high' })
    end

    it 'returns the param directly if it is already a hash' do
      hash_param = { 'direct' => 'hash' }
      result = controller_instance.send(:extract_headers_param, hash_param)
      expect(result).to eq(hash_param)
    end
  end
end
