module Ecommerce
  module EventHandlers
    module Orders
      class Submit
        include Deps[
          "repositories.orders",
        ]

        def call(event)
          orders.create(
            id: event.data[:order_id],
            number: event.data[:order_number]
          )
        end
      end
    end
  end
end
