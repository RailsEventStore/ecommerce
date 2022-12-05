module Orders
  class ExpireOrder < Infra::EventHandler
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.state = "Expired"
      order.save!

      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end