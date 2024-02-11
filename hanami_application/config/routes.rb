# frozen_string_literal: true

module Ecommerce
  class Routes < Hanami::Routes
    post "/orders", to: "orders.create"
    get "/", to: "orders.index"
  end
end
