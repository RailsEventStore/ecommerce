module ClientOrders
  class ConfirmOrder
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.state = "Paid"
      order.save!
    end
  end
end

