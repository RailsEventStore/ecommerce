module Customers
  class RegisterCustomer < Infra::EventHandler
    def call(event)
      Customer.create(id: event.data.fetch(:customer_id), name: event.data.fetch(:name))
    end
  end
end
