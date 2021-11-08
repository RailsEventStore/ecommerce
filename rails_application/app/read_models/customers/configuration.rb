module Customers
  class Customer < ApplicationRecord
    self.table_name = "customers"
  end

  class Configuration

    def call(cqrs)
      cqrs.subscribe(
        -> (event) { register_customer(event) },
        [Crm::CustomerRegistered]
      )
    end

    private

    def register_customer(event)
      Customer.create(id: event.data.fetch(:customer_id), name: event.data.fetch(:name))
    end

    def find(customer_id)
      Customer.where(id: customer_id).first
    end
  end
end
