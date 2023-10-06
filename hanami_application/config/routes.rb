# frozen_string_literal: true

module Ecommerce
  class Routes < Hanami::Routes
    root { "Hello from Hanami" }

    post "/orders", to: "orders.create"
  end
end
