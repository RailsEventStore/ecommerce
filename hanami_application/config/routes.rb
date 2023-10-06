# frozen_string_literal: true

module Ecommerce
  class Routes < Hanami::Routes
    post "/orders", to: "orders.create"
  end
end
