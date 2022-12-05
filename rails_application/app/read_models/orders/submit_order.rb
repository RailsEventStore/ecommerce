module Orders
  class SubmitOrder < Infra::EventHandler
    def call(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!

      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end