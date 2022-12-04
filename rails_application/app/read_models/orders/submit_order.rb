module Orders
  class SubmitOrder < ReadModel
    def call(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!

      link_event_to_stream(event)
    end
  end
end