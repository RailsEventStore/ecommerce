module Orders
  class AssignCustomerToOrder
    def call(event)
      order_uid = event.data.fetch(:order_id)
      Order.find_or_create_by!(uid: order_uid)

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
