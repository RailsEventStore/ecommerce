# frozen_string_literal: true

module Ecommerce
  class Routes < Hanami::Routes
    root { "Hello from Hanami" }

    slice :orders, at: "/orders" do
    end
  end
end
