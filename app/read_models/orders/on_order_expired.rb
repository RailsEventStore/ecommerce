module Orders
  class OnOrderExpired
    def call(event)
      order = Order.find_by_uid(event.data[:order_id])
      order.state = "Expired"
      order.save!
    end
  end
end
