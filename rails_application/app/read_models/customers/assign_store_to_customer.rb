module Customers
  class AssignStoreToCustomer
    def call(event)
      Customer.find_or_create_by(id: event.data.fetch(:customer_id)).update(store_id: event.data.fetch(:store_id))
    end
  end
end
