module Customers
  class UpdatePaidOrdersSummary
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      customer = Customer.find(order.customer_id)
      customer.update(paid_orders_summary: customer.paid_orders_summary + order.discounted_value)
    end
  end
end
