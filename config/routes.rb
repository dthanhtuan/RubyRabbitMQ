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
    post 'work_queue/enqueue', to: 'work_queue#enqueue'
    post 'work_queue/start_worker', to: 'work_queue#start_worker'

  # Pub/Sub Fanout Pattern - Broadcast to all subscribers
  namespace :pub_sub do
    # Fanout pattern
    post 'fanout/broadcast', to: 'fanout#broadcast'
    post 'fanout/start_subscriber', to: 'fanout#start_subscriber'

    # Direct (Routing) pattern
    post 'direct/publish', to: 'direct#publish'
    post 'direct/start_subscriber', to: 'direct#start_subscriber'

    # Topic pattern
    post 'topic/publish', to: 'topic#publish'
    post 'topic/start_subscriber', to: 'topic#start_subscriber'

    # Headers pattern
    post 'headers/publish', to: 'headers#publish'
    post 'headers/start_subscriber', to: 'headers#start_subscriber'
  end

  # Single Queue Pattern - Simple 1P -> 1C example
  post 'single_queue/enqueue', to: 'single_queue#enqueue'
  post 'single_queue/start_consumer', to: 'single_queue#start_consumer'

  # Note: Routing and Topic examples are now under the pub_sub namespace as focused controllers

  # Keep original messages endpoint for backward compatibility
  post "messages", to: "single_queue#enqueue"
end
