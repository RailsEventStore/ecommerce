module Ecommerce
  module EventHandlers
    module Orders
      class Submit
        include Deps[
          "repositories.orders",
        ]

        def call(event)
          orders.create(
            uuid: event.data[:order_id],
            order_number: event.data[:order_number]
          )
        end
      end
    end
  end
end
