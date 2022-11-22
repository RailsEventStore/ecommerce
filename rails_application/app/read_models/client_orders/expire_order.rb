module ClientOrders
  class ExpireOrder < Infra::EventHandler
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.state = "Expired"
      order.save!
    end
  end
end