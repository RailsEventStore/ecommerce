module Orders
  class CreateCustomer < ReadModel
    def call(event)
      Customer.create(
        uid: event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )

      link_event_to_stream(event)
    end
  end
end
