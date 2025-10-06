# frozen_string_literal: true

namespace :rabbitmq do
  desc 'Test Work Queue pattern'
  task test_work_queue: :environment do
    puts "🔧 Testing Work Queue Pattern"
    puts "=" * 50

    # Send a few work tasks to the queue
    3.times do
      message = "Work task ##{Time.current}"
      Rabbitmq::Queue::WorkQueue.enqueue('demo_queue', message)
      puts "📤 Enqueued work: #{message}"
    end

    puts "\n💡 To process these work tasks, run:"
    puts "   Rabbitmq::Queue::WorkQueueJob.perform_later('demo_queue')"
    puts "   or use: rails runner \"Rabbitmq::Queue::WorkQueueJob.new.perform('demo_queue')\""
  end

  desc 'Test Publish/Subscribe Fanout pattern'
  task test_pubsub: :environment do
    puts "📡 Testing Pub/Sub Fanout Pattern"
    puts "=" * 50

    # Start a few subscribers in background threads
    subscribers = ['email_service', 'sms_service', 'push_service']

    puts "🚀 Starting subscribers..."
    threads = subscribers.map do |subscriber_name|
      Thread.new do
        puts "👂 Starting subscriber: #{subscriber_name}"
        Rabbitmq::Exchange::Subscriber.subscribe_to_exchange('demo_exchange', subscriber_name)
      end
    end

    # Give subscribers time to connect
    sleep 2

    # Send some broadcast messages
    3.times do
      message = "Broadcast: System notification - #{Time.current}"
      Rabbitmq::Exchange::Publisher.broadcast('demo_exchange', message)
      puts "📢 Broadcast sent: #{message}"
      sleep 1
    end

    puts "\n✅ All subscribers should have received all messages"
    puts "Press Ctrl+C to stop subscribers"

    # Keep running to see messages being processed
    threads.each(&:join)
  end

  desc 'Test Publish/Subscribe Topic pattern'
  task test_topics: :environment do
    puts "🎯 Testing Pub/Sub Topic Pattern"
    puts "=" * 50

    # Start topic subscribers with different patterns
    subscribers_config = [
      { name: 'user_service', pattern: 'user.*' },
      { name: 'order_service', pattern: 'order.*' },
      { name: 'notification_service', pattern: 'user.created' },
      { name: 'error_service', pattern: '*.error' },
      { name: 'audit_service', pattern: '#' } # Receives all messages
    ]

    puts "🚀 Starting topic subscribers..."
    threads = subscribers_config.map do |config|
      Thread.new do
        puts "👂 Starting #{config[:name]} with pattern '#{config[:pattern]}'"
        Rabbitmq::Exchange::Subscriber.subscribe_to_topic('demo_topic_exchange', config[:pattern], config[:name])
      end
    end

    # Give subscribers time to connect
    sleep 2

    # Send messages with different routing keys
    messages = [
      { routing_key: 'user.created', message: 'New user John Doe registered' },
      { routing_key: 'user.updated', message: 'User profile updated' },
      { routing_key: 'order.created', message: 'Order #1234 created' },
      { routing_key: 'order.completed', message: 'Order #1234 completed' },
      { routing_key: 'payment.error', message: 'Payment processing failed' },
      { routing_key: 'system.maintenance', message: 'System going down for maintenance' }
    ]

    messages.each do |msg_config|
      puts "\n📨 Sending message"
      puts "   Routing Key: #{msg_config[:routing_key]}"
      puts "   Message: #{msg_config[:message]}"

      Rabbitmq::Exchange::Publisher.publish_topic('demo_topic_exchange', msg_config[:routing_key], msg_config[:message])
      sleep 1.5
    end

    puts "\n✅ Check the output above to see which subscribers received which messages"
    puts "Expected routing:"
    puts "  - user_service: receives user.created, user.updated"
    puts "  - order_service: receives order.created, order.completed"
    puts "  - notification_service: receives only user.created"
    puts "  - error_service: receives payment.error"
    puts "  - audit_service: receives all messages"
    puts "\nPress Ctrl+C to stop subscribers"

    # Keep running to see messages being processed
    threads.each(&:join)
  end

  desc 'Start a work queue worker'
  task :start_worker, [:worker_name] => :environment do |_t, args|
    worker_name = args[:worker_name] || 'test_worker'

    puts "⚙️ Starting work queue worker: #{worker_name}"
    puts "   Queue: demo_queue"
    puts "   Press Ctrl+C to stop"

    Rabbitmq::Queue::WorkQueueJob.new.perform('demo_queue')
  end

  desc 'Start a single fanout subscriber'
  task :start_subscriber, [:subscriber_name] => :environment do |_t, args|
    subscriber_name = args[:subscriber_name] || 'test_subscriber'

    puts "👂 Starting fanout subscriber: #{subscriber_name}"
    puts "   Exchange: demo_exchange"
    puts "   Press Ctrl+C to stop"

    Rabbitmq::Exchange::Subscriber.subscribe_to_exchange('demo_exchange', subscriber_name)
  end

  desc 'Start a single topic subscriber'
  task :start_topic_subscriber, [:subscriber_name, :routing_pattern] => :environment do |_t, args|
    subscriber_name = args[:subscriber_name] || 'test_topic_subscriber'
    routing_pattern = args[:routing_pattern] || '#'

    puts "🎯 Starting topic subscriber: #{subscriber_name}"
    puts "   Exchange: demo_topic_exchange"
    puts "   Pattern: #{routing_pattern}"
    puts "   Press Ctrl+C to stop"

    Rabbitmq::Exchange::Subscriber.subscribe_to_topic('demo_topic_exchange', routing_pattern, subscriber_name)
  end

  desc 'Send work to queue'
  task :send_work, [:message] => :environment do |_t, args|
    message = args[:message] || "Test work task - #{Time.current}"

    Rabbitmq::Queue::WorkQueue.enqueue('demo_queue', message)
    puts "⚙️ Work enqueued: #{message}"
  end

  desc 'Send a single fanout broadcast'
  task :send_broadcast, [:message] => :environment do |_t, args|
    message = args[:message] || "Test broadcast message - #{Time.current}"

    Rabbitmq::Exchange::Publisher.broadcast('demo_exchange', message)
    puts "📢 Broadcast sent: #{message}"
  end

  desc 'Send a single topic message'
  task :send_topic, [:routing_key, :message] => :environment do |_t, args|
    routing_key = args[:routing_key] || 'test.message'
    message = args[:message] || "Test topic message - #{Time.current}"

    Rabbitmq::Exchange::Publisher.publish_topic('demo_topic_exchange', routing_key, message)
    puts "🎯 Topic message sent:"
    puts "   Routing Key: #{routing_key}"
    puts "   Message: #{message}"
  end
end
