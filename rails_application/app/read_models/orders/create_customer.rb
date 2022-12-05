module Orders
  class CreateCustomer < Infra::EventHandler
    def call(event)
      Customer.create(
        uid: event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )

      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end
