class PubSub::HeadersController < ApplicationController
  DEMO_HEADERS_EXCHANGE = "demo_headers_exchange"

  # Publish to headers exchange with provided headers (expects JSON or form fields)
  def publish
    message = params[:message] || "Headers message from Rails at #{Time.now}"
    headers_hash = extract_headers_param(params[:headers])

    Rabbitmq::Exchange::Publisher.publish_headers(DEMO_HEADERS_EXCHANGE, headers_hash, message)

    render json: {
      status: "Message published to headers exchange",
      message: message,
      exchange: DEMO_HEADERS_EXCHANGE,
      headers: headers_hash
    }
  end

  # Start a headers exchange subscriber with binding headers
  def start_subscriber
    subscriber_name = params[:subscriber_name] || "headers_subscriber_#{SecureRandom.hex(4)}"
    headers_hash = extract_headers_param(params[:headers])

    Thread.new do
      Rabbitmq::Exchange::Subscriber.subscribe_to_headers(DEMO_HEADERS_EXCHANGE, headers_hash, subscriber_name)
    end

    render json: {
      status: "Headers subscriber started",
      subscriber_name: subscriber_name,
      exchange: DEMO_HEADERS_EXCHANGE,
      bind_headers: headers_hash,
      note: "Headers subscriber is running in background thread"
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
