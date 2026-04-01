module OrderHeader
  class RenameCustomer
    def call(event)
      customer = Customer.find_by(customer_id: event.data.fetch(:customer_id))
      old_name = customer.name
      customer.update!(name: event.data.fetch(:name))
      Header.where(customer: old_name).update_all(customer: event.data.fetch(:name))
    end
  end
end
