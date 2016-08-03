Rails.application.routes.draw do
  root 'orders#index'

  resources :orders, only: [:index, :show, :new, :create] do
    member do
      post 'add_item'
      post 'remove_item'
    end
  end
end
