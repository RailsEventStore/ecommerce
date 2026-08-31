# frozen_string_literal: true

module HanamiApplication
  class Routes < Hanami::Routes
    root to: "cart.show"
    post "/cart/items", to: "cart.add_item", as: :add_item
    post "/cart/submit", to: "cart.submit", as: :submit
    get "/orders/:id", to: "orders.show", as: :order
  end
end
