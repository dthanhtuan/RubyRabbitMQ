# frozen_string_literal: true

require 'bunny'

module Rabbitmq
  module Queue
    class WorkQueueJob < ApplicationJob
      queue_as :default

      # Process work from a specific queue (work queue pattern)
      def perform(queue_name)
        connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
        connection.start
        channel = connection.create_channel
        queue = channel.queue(queue_name, durable: true)
        begin
          queue.subscribe(block: true) do |_delivery_info, _properties, body|
            Rails.logger.info "Processing work from queue '#{queue_name}': #{body}"
            process_work(body)
          end
        ensure
          connection.close
        end
      end

      # Process subscriber messages from fanout exchange (pub/sub pattern)
      def perform_subscriber(exchange_name, subscriber_name)
        Rabbitmq::Exchange::Subscriber.subscribe_to_exchange(exchange_name, subscriber_name) do |_delivery_info, _properties, body|
          Rails.logger.info "Subscriber '#{subscriber_name}' processing: #{body}"
          process_pubsub_message(body, subscriber_name)
        end
      end

      # Process topic subscriber messages (topic pub/sub pattern)
      def perform_topic_subscriber(exchange_name, routing_pattern, subscriber_name)
        Rabbitmq::Exchange::Subscriber.subscribe_to_topic(exchange_name, routing_pattern, subscriber_name) do |delivery_info, _properties, body|
          Rails.logger.info "Topic subscriber '#{subscriber_name}' processing: #{body} (routing: #{delivery_info.routing_key})"
          process_topic_message(body, subscriber_name, delivery_info.routing_key)
        end
      end

      # Process direct exchange subscriber messages (routing pattern)
      def perform_direct_subscriber(exchange_name, routing_key, subscriber_name)
        Rabbitmq::Exchange::Subscriber.subscribe_to_direct(exchange_name, routing_key, subscriber_name) do |delivery_info, _properties, body|
          Rails.logger.info "Direct subscriber '#{subscriber_name}' processing: #{body} (routing: #{delivery_info.routing_key})"
          process_topic_message(body, subscriber_name, delivery_info.routing_key)
        end
      end

      private

      def process_work(message)
        Rails.logger.info "Default work processing: #{message}"
      end

      def process_pubsub_message(message, subscriber_name)
        Rails.logger.info "Default processing for subscriber #{subscriber_name}: #{message}"
      end

      def process_topic_message(message, subscriber_name, routing_key)
        Rails.logger.info "Default topic processing for subscriber #{subscriber_name} (#{routing_key}): #{message}"
      end
    end
  end
end

