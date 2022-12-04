module Orders
  class ConfirmOrder < ReadModel
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.state = "Paid"
      order.save!

      link_event_to_stream(event)
    end
  end
end