class TopicController < ApplicationController
  DEMO_TOPIC_EXCHANGE = 'demo_topic_exchange'

  # Publish message with routing key for selective delivery
  def publish
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
  def start_subscriber
    subscriber_name = params[:subscriber_name] || "topic_subscriber_#{SecureRandom.hex(4)}"
    routing_pattern = params[:routing_pattern] || '#' # '#' means all messages

    # This would typically be run in a separate process or background job
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
end
