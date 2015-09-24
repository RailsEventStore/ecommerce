module Denormalizers
  class OrderCreated
    def handle_event(event)
      return if Order.where(uid: event.order_id).exists?
      order = ::Order.new.tap do |o|
        o.uid = event.order_id
        o.number = event.order_number
        o.customer = Customer.find(event.customer_id).name
        o.state = "Created"
      end
      order.save!
    end
  end
end
