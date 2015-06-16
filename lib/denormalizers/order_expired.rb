module Denormalizers
  class OrderExpired
    def handle_event(event)
      order = ::Order.find_by_uid(event.order_id)
      order.state = "Expired"
      order.save!
    end
  end
end
