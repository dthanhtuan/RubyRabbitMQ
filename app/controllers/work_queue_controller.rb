class WorkQueueController < ApplicationController
  DEMO_QUEUE = 'demo_queue'

  # Send work task to queue for processing by workers
  def enqueue
    message = params[:message] || "Work task from Rails at #{Time.now}"
    Rabbitmq::Queue::WorkQueue.enqueue(DEMO_QUEUE, message)

    render json: {
      status: 'Work enqueued',
      message: message,
      queue: DEMO_QUEUE,
      pattern: 'Work Queue - one worker will process this task'
    }
  end

  # Start a worker to process tasks from the queue
  def start_worker
    worker_name = params[:worker_name] || "worker_#{SecureRandom.hex(4)}"

    # This would typically be run in a separate process or background job
    Thread.new do
      Rails.logger.info "Starting work queue worker: #{worker_name}"
      Rabbitmq::Queue::WorkQueueJob.new.perform(DEMO_QUEUE)
    end

    render json: {
      status: 'Work queue worker started',
      worker_name: worker_name,
      queue: DEMO_QUEUE,
      note: 'Worker is running in background thread'
    }
  end
end
