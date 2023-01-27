module Customers
  class UpdatePaidOrdersSummary < Infra::EventHandler
    def call(event)
      order = ClientOrders::Order.find_by(order_uid: event.data.fetch(:order_id))
      customer = Customer.find(order.client_uid)
      customer.update(paid_orders_summary: customer.paid_orders_summary + order.discounted_value)
    end
  end
end
