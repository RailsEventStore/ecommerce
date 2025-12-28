module Customers
  class RegisterCustomer
    def call(event)
      Customer.find_or_create_by(id: event.data.fetch(:customer_id)).update(name: event.data.fetch(:name))
    end
  end
end
