module Orders
  class OnOrderSubmitted
    def call(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.customer = Crm::Customer.find(event.data.fetch(:customer_id)).name
      order.state = "Submitted"
      order.save!
    end
  end
end
