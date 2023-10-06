module Ecommerce
  module Views
    module Orders
      class Index < Ecommerce::View
        include Deps[
          "repositories.orders"
        ]

        expose :orders do
          orders.all
        end
      end
    end
  end
end
