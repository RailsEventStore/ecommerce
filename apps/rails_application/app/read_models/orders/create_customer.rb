module Orders
  class CreateCustomer
    def call(event)
      Customer.create(
        uid: event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
