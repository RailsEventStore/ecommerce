module Orders
  class SubmitOrder < Infra::EventHandler
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
  end
end