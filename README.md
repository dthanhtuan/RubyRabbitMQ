# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

## RabbitMQ Example Usage

### 1. Start the app and dependencies with Docker Compose

```
docker-compose up --build
```

- Rails app: http://localhost:3000
- RabbitMQ Management UI: http://localhost:15672 (user: guest, pass: guest)
- Postgres: localhost:5432

### 2. Publish a message to RabbitMQ

Send a POST request to `/messages` with an optional `message` parameter:

```
curl -X POST -d 'message=HelloRabbit' http://localhost:3000/messages
```

### 3. Consume messages from RabbitMQ

To consume messages, run the consumer job in a Rails console:

```
docker-compose exec web rails runner 'RabbitmqConsumerJob.perform_now("demo_queue")'
```

This will log consumed messages to the Rails log.

### 4. Run the RSpec test suite

```
docker-compose exec web bundle exec rspec
```

This will run the test in `spec/services/rabbitmq_producer_spec.rb` to verify message publishing.

---

For more details, see the code in `app/services/rabbitmq_producer.rb`, `app/jobs/rabbitmq_consumer_job.rb`, and `app/controllers/messages_controller.rb`
