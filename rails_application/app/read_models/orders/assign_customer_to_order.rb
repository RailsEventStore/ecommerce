module Orders
  class AssignCustomerToOrder
    def call(event)
      order_uid = event.data.fetch(:order_id)
      ApplicationRecord.with_advisory_lock(order_uid) do
        order = Order.find_or_create_by!(uid: order_uid) { |order| order.state = "Draft" }
        order.customer = Customer.find_by_uid(event.data.fetch(:customer_id)).name
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
