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
    end
    resource :shipping_address, only: [:new, :create]
  end
  resources :products, only: [:new, :show, :create, :index] do
    resources :supplies, only: [:new, :create]
  end
  resources :customers, only: [:new, :create, :index]

  mount RailsEventStore::Browser => "/res"
end
