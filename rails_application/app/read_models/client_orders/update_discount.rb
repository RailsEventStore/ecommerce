module ClientOrders
  class UpdateDiscount < Infra::EventHandler
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.percentage_discount = event.data.fetch(:amount)
      order.save!
    end
  end
end

