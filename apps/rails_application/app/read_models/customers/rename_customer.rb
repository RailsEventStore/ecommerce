module Customers
  class RenameCustomer
    def call(event)
      Customer.find_by(id: event.data.fetch(:customer_id)).update(name: event.data.fetch(:name))
    end
  end
end
