# RabbitMQ Overview: Enqueue and Receive Examples

This file provides concise Ruby (Bunny) examples showing how messages are enqueued and received for each RabbitMQ pattern used in this project.

## Single queue (direct to a named queue)
```ruby
# Enqueue
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
queue = channel.queue('demo_queue', durable: true)
queue.publish('hello single', persistent: true)
connection.close

# Receive
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
queue = channel.queue('demo_queue', durable: true)
queue.subscribe(block: true) do |_delivery_info, _properties, body|
  puts "Single received: #{body}"
end
```

## Work queue (task distribution; consumer uses prefetch + manual ack)
```ruby
# Enqueue (same as single queue)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
queue = channel.queue('work_queue', durable: true)
queue.publish('do work', persistent: true)
connection.close

# Worker (consumer)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
channel.prefetch(1) # fair dispatch - one message at a time
queue = channel.queue('work_queue', durable: true)
queue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
  begin
    puts "Working on: #{body}"
    # perform work...
    channel.ack(delivery_info.delivery_tag)
  rescue
    channel.nack(delivery_info.delivery_tag, false, true)
  end
end
```

## Fanout exchange (broadcast)
```ruby
# Enqueue (publish to fanout exchange)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.fanout('demo_exchange', durable: true)
exchange.publish('broadcast', persistent: true)
connection.close

# Subscriber (each subscriber gets its own queue)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.fanout('demo_exchange', durable: true)
queue = channel.queue('demo_exchange.my_subscriber', exclusive: false, auto_delete: true)
queue.bind(exchange)
queue.subscribe(block: true) do |_delivery_info, _properties, body|
  puts "Fanout received: #{body}"
end
```

## Direct exchange (Routing pattern — exact routing_key)
```ruby
# Enqueue
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.direct('demo_direct_exchange', durable: true)
exchange.publish('critical payload', routing_key: 'error.critical', persistent: true)
connection.close

# Receive (bind to exact routing key)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.direct('demo_direct_exchange', durable: true)
queue = channel.queue('demo_direct_exchange.error_handler', exclusive: false, auto_delete: true)
queue.bind(exchange, routing_key: 'error.critical')
queue.subscribe(block: true) do |delivery_info, _properties, body|
  puts "Direct received [#{delivery_info.routing_key}]: #{body}"
end
```

## Topic exchange (Topic pattern — '*' and '#' wildcards)
```ruby
# Enqueue
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.topic('demo_topic_exchange', durable: true)
exchange.publish('user created', routing_key: 'user.created', persistent: true)
connection.close

# Receive (bind using pattern; '*' = one word, '#' = zero-or-more words)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.topic('demo_topic_exchange', durable: true)
queue = channel.queue('demo_topic_exchange.user_service', exclusive: false, auto_delete: true)
queue.bind(exchange, routing_key: 'user.*')
queue.subscribe(block: true) do |delivery_info, _properties, body|
  puts "Topic received [#{delivery_info.routing_key}]: #{body}"
end
```

## Headers exchange (header-based routing)
```ruby
# Enqueue (set headers on published message)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.headers('demo_headers_exchange', durable: true)
exchange.publish('report payload', headers: { 'type' => 'report' }, persistent: true)
connection.close

# Receive (bind with header matching)
connection = Bunny.new(hostname: ENV.fetch('RABBITMQ_HOST', 'localhost'))
connection.start
channel = connection.create_channel
exchange = channel.headers('demo_headers_exchange', durable: true)
queue = channel.queue('demo_headers_exchange.report_service', exclusive: false, auto_delete: true)
queue.bind(exchange, arguments: { 'x-match' => 'all', 'type' => 'report' })
queue.subscribe(block: true) do |_delivery_info, properties, body|
  puts "Headers received [#{properties.headers.inspect}]: #{body}"
end
```

## Notes:
- Queues/exchanges are declared durable and messages are published persistent where appropriate in this project.
- For work queues, set prefetch and use manual acknowledgements on the consumer side for fair dispatch.
- Topic patterns: '*' matches exactly one word, '#' matches zero-or-more words.
