module Denormalizers
  class OrderCreated
    def call(event)
      order = Order.find_by(uid: event.data[:order_id])
      order.number = event.data[:order_number]
      order.customer = Customer.find(event.data[:customer_id]).name
      order.state = "Created"
      order.save!
    end
  end
end
