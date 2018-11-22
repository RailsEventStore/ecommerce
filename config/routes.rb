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
  mount RubyEventStore::Browser::App.for(
    event_store_locator: -> { Rails.configuration.event_store }
  ) => '/res'
end
