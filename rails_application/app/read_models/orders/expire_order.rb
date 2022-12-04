module Orders
  class ExpireOrder < ReadModel
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.state = "Expired"
      order.save!

      link_event_to_stream(event)
    end
  end
end