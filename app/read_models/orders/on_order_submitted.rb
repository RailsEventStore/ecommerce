module Orders
  class OnOrderSubmitted
    def call(event)
      order = Order.find_by(uid: event.data[:order_id])
      order.number = event.data[:order_number]
      order.customer = Customer.find(event.data[:customer_id]).name
      order.state = "Submitted"
      order.save!
    end
  end
end
