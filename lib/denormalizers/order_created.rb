module Denormalizers
  class OrderCreated
    def call(event)
      return if Order.where(uid: event.data.order_id).exists?
      order = ::Order.new.tap do |o|
        o.uid = event.data.order_id
        o.number = event.data.order_number
        o.customer = Customer.find(event.data.customer_id).name
        o.state = "Created"
      end
      order.save!
    end
  end
end
