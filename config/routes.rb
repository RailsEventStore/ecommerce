Rails.application.routes.draw do
  root 'orders#index'

  resources :orders, only: [:index, :show, :new, :create] do
    collection do
      post :expire
    end
    member do
      post :add_item
      post :remove_item
    end
  end

  require 'ruby_event_store/browser/app'
  browser = ->(env) do
    request = Rack::Request.new(env)
    app = RubyEventStore::Browser::App.for(
      event_store_locator: -> { Rails.configuration.event_store },
      host: request.base_url,
      path: request.script_name
    )
    app.call(env)
  end
  mount browser => '/res'
end
