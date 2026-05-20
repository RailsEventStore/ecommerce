module Customers
  class UpdateOrderTotalValue
    def call(event)
      Order.find_or_create_by(order_uid: event.data.fetch(:order_id))
        .update(discounted_value: event.data.fetch(:discounted_amount))
    end
  end
end
