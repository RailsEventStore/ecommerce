module Customers
  class RegisterCustomer < Infra::EventHandler
    def call(event)
      ApplicationRecord.with_advisory_lock(event.data.fetch(:customer_id)) do
        Customer.find_or_create_by(id: event.data.fetch(:customer_id)).update(name: event.data.fetch(:name))
      end
    end
  end
end
