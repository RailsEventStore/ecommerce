Rails.application.routes.draw do
  root 'orders#index'

  resources :orders, only: [:index, :show, :new, :create] do
    collection do
      post :expire
    end
    member do
      get :history
      post :add_item
      post :remove_item
    end
  end
end
