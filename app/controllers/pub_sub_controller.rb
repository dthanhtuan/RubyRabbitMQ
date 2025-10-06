class PubSubController < ApplicationController
  DEMO_EXCHANGE = 'demo_exchange'
  DEMO_DIRECT_EXCHANGE = 'demo_direct_exchange'
  DEMO_TOPIC_EXCHANGE = 'demo_topic_exchange'
  DEMO_HEADERS_EXCHANGE = 'demo_headers_exchange'

  # Broadcast message to all subscribers using fanout exchange
  def broadcast
    message = params[:message] || "Broadcast message from Rails at #{Time.now}"
    Rabbitmq::Exchange::Publisher.broadcast(DEMO_EXCHANGE, message)

    render json: {
      status: 'Message broadcasted',
      message: message,
      exchange: DEMO_EXCHANGE,
      pattern: 'Fanout - all subscribers receive this message'
    }
  end

  # Start a subscriber to receive all broadcast messages
  def start_subscriber
    subscriber_name = params[:subscriber_name] || "subscriber_#{SecureRandom.hex(4)}"

    Thread.new do
      Rabbitmq::Exchange::Subscriber.subscribe_to_exchange(DEMO_EXCHANGE, subscriber_name)
    end

    render json: {
      status: 'Subscriber started',
      subscriber_name: subscriber_name,
      exchange: DEMO_EXCHANGE,
      note: 'Subscriber is running in background thread'
    }
  end

  # Publish to a direct exchange with routing key
  def publish_direct
    message = params[:message] || "Direct message from Rails at #{Time.now}"
    routing_key = params[:routing_key] || 'info'

    Rabbitmq::Exchange::Publisher.publish_direct(DEMO_DIRECT_EXCHANGE, routing_key, message)

    render json: {
      status: 'Message published to direct exchange',
      message: message,
      exchange: DEMO_DIRECT_EXCHANGE,
      routing_key: routing_key,
      pattern: 'Direct - messages routed by exact routing key'
    }
  end

  # Start a direct exchange subscriber for a specific routing key
  def start_direct_subscriber
    subscriber_name = params[:subscriber_name] || "direct_subscriber_#{SecureRandom.hex(4)}"
    routing_key = params[:routing_key] || 'info'

    Thread.new do
      Rabbitmq::Exchange::Subscriber.subscribe_to_direct(DEMO_DIRECT_EXCHANGE, routing_key, subscriber_name)
    end

    render json: {
      status: 'Direct subscriber started',
      subscriber_name: subscriber_name,
      exchange: DEMO_DIRECT_EXCHANGE,
      routing_key: routing_key,
      note: 'Direct subscriber is running in background thread'
    }
  end

  # Publish message to topic exchange with routing key
  def publish_topic
    message = params[:message] || "Topic message from Rails at #{Time.now}"
    routing_key = params[:routing_key] || 'general.info'

    Rabbitmq::Exchange::Publisher.publish_topic(DEMO_TOPIC_EXCHANGE, routing_key, message)

    render json: {
      status: 'Message published to topic',
      message: message,
      exchange: DEMO_TOPIC_EXCHANGE,
      routing_key: routing_key,
      pattern: 'Topic - subscribers with matching patterns receive this message'
    }
  end

  # Start a topic subscriber with routing pattern
  def start_topic_subscriber
    subscriber_name = params[:subscriber_name] || "topic_subscriber_#{SecureRandom.hex(4)}"
    routing_pattern = params[:routing_pattern] || '#' # '#' means all messages

    Thread.new do
      Rabbitmq::Exchange::Subscriber.subscribe_to_topic(DEMO_TOPIC_EXCHANGE, routing_pattern, subscriber_name)
    end

    render json: {
      status: 'Topic subscriber started',
      subscriber_name: subscriber_name,
      exchange: DEMO_TOPIC_EXCHANGE,
      routing_pattern: routing_pattern,
      note: 'Topic subscriber is running in background thread'
    }
  end

  # Publish message to headers exchange with provided headers (expects JSON or form fields)
  def publish_headers
    message = params[:message] || "Headers message from Rails at #{Time.now}"

    headers_hash = extract_headers_param(params[:headers])

    Rabbitmq::Exchange::Publisher.publish_headers(DEMO_HEADERS_EXCHANGE, headers_hash, message)

    render json: {
      status: 'Message published to headers exchange',
      message: message,
      exchange: DEMO_HEADERS_EXCHANGE,
      headers: headers_hash
    }
  end

  # Start a headers exchange subscriber with binding headers
  def start_headers_subscriber
    subscriber_name = params[:subscriber_name] || "headers_subscriber_#{SecureRandom.hex(4)}"
    headers_hash = extract_headers_param(params[:headers])

    Thread.new do
      Rabbitmq::Exchange::Subscriber.subscribe_to_headers(DEMO_HEADERS_EXCHANGE, headers_hash, subscriber_name)
    end

    render json: {
      status: 'Headers subscriber started',
      subscriber_name: subscriber_name,
      exchange: DEMO_HEADERS_EXCHANGE,
      bind_headers: headers_hash,
      note: 'Headers subscriber is running in background thread'
    }
  end

  private

  def extract_headers_param(param)
    return {} if param.blank?

    if param.is_a?(String)
      begin
        JSON.parse(param)
      rescue StandardError
        {}
      end
    elsif param.respond_to?(:to_unsafe_h)
      param.to_unsafe_h
    else
      param
    end
  end
end
