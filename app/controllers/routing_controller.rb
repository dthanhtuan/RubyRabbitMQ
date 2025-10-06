class RoutingController < ApplicationController
  DEMO_DIRECT_EXCHANGE = 'demo_direct_exchange'

  # Publish message to direct exchange with a routing key
  def publish
    message = params[:message] || "Routing message from Rails at #{Time.now}"
    routing_key = params[:routing_key] || 'info'

    Rabbitmq::Exchange::Publisher.publish_direct(DEMO_DIRECT_EXCHANGE, routing_key, message)

    render json: {
      status: 'Message published to direct exchange',
      message: message,
      exchange: DEMO_DIRECT_EXCHANGE,
      routing_key: routing_key,
      pattern: 'Direct/Routing - messages routed to queues by exact routing key'
    }
  end

  # Start a direct exchange subscriber for a specific routing key
  def start_subscriber
    subscriber_name = params[:subscriber_name] || "direct_subscriber_#{SecureRandom.hex(4)}"
    routing_key = params[:routing_key] || 'info'

    Thread.new do
      Rabbitmq::Queue::WorkQueueJob.new.perform_direct_subscriber(DEMO_DIRECT_EXCHANGE, routing_key, subscriber_name)
    end

    render json: {
      status: 'Direct subscriber started',
      subscriber_name: subscriber_name,
      exchange: DEMO_DIRECT_EXCHANGE,
      routing_key: routing_key,
      note: 'Direct subscriber is running in background thread'
    }
  end
end
