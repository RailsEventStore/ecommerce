Rails.application.routes.draw do
  root "todos#index"

  resources :todos, only: [:create, :update, :destroy] do
    member do
      post :complete
      post :uncomplete
    end
    collection do
      delete :clear_completed
    end
  end

  get "/active", to: "todos#index", defaults: { filter: "active" }
  get "/completed", to: "todos#index", defaults: { filter: "completed" }

  get "up" => "rails/health#show", as: :rails_health_check
end
