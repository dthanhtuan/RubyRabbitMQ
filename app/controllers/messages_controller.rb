class MessagesController < ApplicationController
  DEMO_QUEUE = 'demo_queue'

  def create
    message = params[:message] || "Hello from Rails at #{Time.now}"
    RabbitmqProducer.publish(DEMO_QUEUE, message)
    render json: { status: 'Message published', message: message }
  end
end
