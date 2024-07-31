module Orders
  class SubmitOrder
    def call(event)
      order_id = event.data.fetch(:order_id)
      ApplicationRecord.with_advisory_lock(order_id) do
        order = Order.find_or_create_by!(uid: order_id)
        order.number = event.data.fetch(:order_number)
        order.state = "Submitted"
        order.save!
      end
      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end

