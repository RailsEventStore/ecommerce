Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "applications#index"

  resources :applications, only: [:index, :new, :create] do
    member do
      post :evaluate_risk
      post :calculate_premium
      post :accept_offer
    end
  end

  resources :policies, only: [:index] do
    member do
      post :pay_premium
      post :terminate
    end
  end

  resources :claims, only: [:index, :new, :create] do
    member do
      post :evaluate
    end
  end
end
