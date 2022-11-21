module ClientOrders
  class CreateCustomer < Infra::EventHandler
    def call(event)
      Client.create(
        uid: event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )
    end
  end
end
