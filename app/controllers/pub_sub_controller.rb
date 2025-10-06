class PubSubController < ApplicationController
  DEMO_EXCHANGE = 'demo_exchange'

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

    # This would typically be run in a separate process or background job
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
end
