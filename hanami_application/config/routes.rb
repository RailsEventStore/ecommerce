# frozen_string_literal: true

require "hanami/application/routes"

module Ecommerce
  class Routes < Hanami::Application::Routes
    define do
      slice :crm, at: "/crm" do
        root to: "home.show"
        post '/customers', to: "customers.create"
        # , only: [:new, :create, :index, :update]
      end
    end
  end
end
