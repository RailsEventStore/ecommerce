module Denormalizers
  class Order
    def order_created(event)
      order = ::Order.new.tap do |o|
        o.uid = event.order_id
        o.number = event.order_number
        o.customer = Customer.find(event.customer_id).name
        o.state = "Created"
      end
      order.save!
    end

    def order_expired(event)
      order = ::Order.find_by_uid(event.order_id)
      order.state = "Expired"
      order.save!
    end
  end
end
