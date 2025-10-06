class SingleQueueController < ApplicationController
  DEMO_QUEUE = 'single_demo_queue'

  # Send a simple message to a single queue (1P -> 1C)
  def enqueue
    message = params[:message] || "Single queue message from Rails at #{Time.now}"
    # Use the queue-publish helper
    Rabbitmq::Queue::Publisher.publish(DEMO_QUEUE, message)

    render json: {
      status: 'Message enqueued to single queue',
      message: message,
      queue: DEMO_QUEUE,
      pattern: 'Single Queue - one producer and one consumer'
    }
  end

  # Start a simple consumer for the single queue
  def start_consumer
    consumer_name = params[:consumer_name] || "consumer_#{SecureRandom.hex(4)}"

    Thread.new do
      Rails.logger.info "Starting single queue consumer: #{consumer_name}"
      # Use namespaced job
      Rabbitmq::Queue::WorkQueueJob.new.perform(DEMO_QUEUE)
    end

    render json: {
      status: 'Single queue consumer started',
      consumer_name: consumer_name,
      queue: DEMO_QUEUE,
      note: 'Consumer is running in background thread'
    }
  end
end
