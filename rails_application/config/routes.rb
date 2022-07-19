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

  resources :shipments, only: [:index]

  resources :invoices, only: [:show]

  resources :products, only: [:new, :show, :create, :index] do
    resources :supplies, only: [:new, :create]
  end

  resources :coupons, only: [:new, :show, :create, :index]
  resources :time_promotions, only: [:new, :show, :create, :index]

  resources :customers, only: [:new, :create, :index, :update]

  resources :client_orders, only: [:index, :show], controller: 'client/orders'
  post :login, to: "client/clients#login"
  get :logout, to: "client/clients#logout"
  get "clients", to: "client/clients#index"
  get "client/products", to: "client/products#index"


  match("architecture", to: "architecture#index", via: :get)
  mount RailsEventStore::Browser => "/res"
end
