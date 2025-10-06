Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Work Queue Pattern - Task distribution among workers
  namespace :work_queue do
    post 'enqueue', to: 'work_queue#enqueue'
    post 'start_worker', to: 'work_queue#start_worker'
  end

  # Pub/Sub Fanout Pattern - Broadcast to all subscribers
  namespace :pub_sub do
    post 'broadcast', to: 'pub_sub#broadcast'
    post 'start_subscriber', to: 'pub_sub#start_subscriber'
    # Additional exchange patterns supported by PubSubController for demo purposes
    post 'publish_direct', to: 'pub_sub#publish_direct'
    post 'start_direct_subscriber', to: 'pub_sub#start_direct_subscriber'
    post 'publish_topic', to: 'pub_sub#publish_topic'
    post 'start_topic_subscriber', to: 'pub_sub#start_topic_subscriber'
    post 'publish_headers', to: 'pub_sub#publish_headers'
    post 'start_headers_subscriber', to: 'pub_sub#start_headers_subscriber'
  end

  # Topic Pattern - Selective message routing
  namespace :topic do
    post 'publish', to: 'topic#publish'
    post 'start_subscriber', to: 'topic#start_subscriber'
  end

  # Single Queue Pattern - Simple 1P -> 1C example
  namespace :single_queue do
    post 'enqueue', to: 'single_queue#enqueue'
    post 'start_consumer', to: 'single_queue#start_consumer'
  end

  # Routing (Direct) Pattern - Exact routing keys
  namespace :routing do
    post 'publish', to: 'routing#publish'
    post 'start_subscriber', to: 'routing#start_subscriber'
  end

  # Keep original messages endpoint for backward compatibility
  post "messages", to: "single_queue#enqueue"
end
