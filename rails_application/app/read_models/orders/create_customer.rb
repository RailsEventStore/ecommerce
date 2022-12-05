module Orders
  class CreateCustomer < Infra::EventHandler
    def call(event)
      Customer.create(
        uid: event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end
