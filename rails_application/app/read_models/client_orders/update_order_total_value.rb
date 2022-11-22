module ClientOrders
  class UpdateOrderTotalValue < Infra::EventHandler
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.discounted_value = event.data.fetch(:discounted_amount)
      order.total_value = event.data.fetch(:total_amount)
      order.save!
    end
  end
end
