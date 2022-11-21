module ClientOrders
  class SubmitOrder < Infra::EventHandler
    def call(event)
      order = Order.find_or_create_by(order_uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!
    end
  end
end