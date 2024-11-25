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
      post :remove_discount
    end
    resource :shipping_address, only: [:edit, :update]
    resource :billing_address, only: [:edit, :update]
    resource :invoice, only: [:create]
  end

  resources :shipments, only: [:index, :show]

  resources :events_catalog, only: [:index]

  resources :invoices, only: [:show]

  resources :products, only: [:new, :show, :create, :index, :edit, :update] do
    resources :supplies, only: [:new, :create]
    member do
      post :add_future_price, to: "product/future_price#add_future_price", as: "add_future_price"
    end
  end


  resources :coupons, only: [:new, :show, :create, :index]
  resources :time_promotions, only: [:new, :show, :create, :index]

  resources :customers, only: [:new, :create, :index, :update, :show]

  resources :client_orders, only: [:index, :show, :new, :edit, :update, :create], controller: 'client/orders' do
    member do
      post :add_item
      post :remove_item
      post :use_coupon
    end
  end

  resources :available_vat_rates, only: [:new, :create, :index]
  delete "/available_vat_rates", to: "available_vat_rates#destroy"

  post :login, to: "client/clients#login"
  get :logout, to: "client/clients#logout"
  get "clients", to: "client/clients#index"
  get "client/products", to: "client/products#index"

  mount RailsEventStore::Browser => "/res"
end
