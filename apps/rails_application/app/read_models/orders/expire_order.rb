module Orders
  class ExpireOrder
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.state = "Expired"
      order.save!

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end

