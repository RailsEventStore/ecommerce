module ClientOrders
  class UpdateDiscount
    def call(event)
      order = Order.find_or_create_by!(order_uid: event.data.fetch(:order_id))
      order.percentage_discount = event.data.fetch(:amount)
      order.save!
    end
  end
end
