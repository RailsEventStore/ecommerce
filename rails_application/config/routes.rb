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

  get "/client", to: "client_orders#index"
  get "/client/:id", to: "client_orders#show"
  post "/client", to: "client_orders#login"

  match("architecture", to: "architecture#index", via: :get)
  mount RailsEventStore::Browser => "/res"
end
