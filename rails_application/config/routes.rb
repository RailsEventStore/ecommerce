Rails.application.routes.draw do
  root "orders#index"

  resources :orders, only: [:index, :show, :new, :edit, :create] do
    collection do
      post :expire
    end
    member do
      post :add_item
      post :remove_item
      post :pay
      post :cancel
      get :edit_discount
      post :update_discount
      post :reset_discount
    end
    resource :shipping_address, only: [:edit, :update]
    resource :billing_address, only: [:edit, :update]
    resource :invoice, only: [:create]
  end

  resources :invoices, only: [:show]

  resources :products, only: [:new, :show, :create, :index] do
    resources :supplies, only: [:new, :create]
  end

  resources :coupons, only: [:new, :show, :create, :index] do

  end
  resources :customers, only: [:new, :create, :index, :update]

  resources :clients, only: :index do
    resources :orders, only: [:index, :show], controller: 'client/orders'
  end
  post :login, to: "clients#login"


  match("architecture", to: "architecture#index", via: :get)
  mount RailsEventStore::Browser => "/res", :as => :ruby_event_store_browser_app
end
