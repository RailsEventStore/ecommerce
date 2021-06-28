Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  root 'orders#index'

  resources :orders, only: [:index, :show, :new, :edit, :create] do
    collection do
      post :expire
    end
    member do
      post :add_item
      post :remove_item
      post :pay
    end
  end
  resources :products, only: [:new, :create, :index]
  resources :customers, only: [:new, :create, :index]

  mount RailsEventStore::Browser => '/res'
end
