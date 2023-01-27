module ClientOrders
  class UpdatePaidOrdersSummary < Infra::EventHandler
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      client = Client.where(uid: order.client_uid).first
      client.update(paid_orders_summary: client.paid_orders_summary + order.discounted_value)
    end
  end
end
