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
  end

  resources :invoices, only: [:show]

  resources :products, only: [:new, :show, :create, :index] do
    resources :supplies, only: [:new, :create]
  end
  resources :customers, only: [:new, :create, :index]

  match("architecture", to: "architecture#index", via: :get)
  mount RailsEventStore::Browser => "/res"
end
