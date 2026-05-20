module Customers
  class AssignCustomerToOrder
    def call(event)
      Order.find_or_create_by(order_uid: event.data.fetch(:order_id))
        .update(customer_id: event.data.fetch(:customer_id))
    end
  end
end
