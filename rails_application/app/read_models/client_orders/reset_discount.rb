module ClientOrders
  class ResetDiscount < Infra::EventHandler
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      unless order.nil?
        order.percentage_discount = nil
        order.save!
      end
    end
  end
end
