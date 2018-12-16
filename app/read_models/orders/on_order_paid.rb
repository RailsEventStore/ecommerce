module Orders
  class OnOrderPaid
    def call(event)
      order = Order.find_by_uid(event.data[:order_id])
      order.state = "Ready to ship (paid)"
      order.save!
    end
  end
end
