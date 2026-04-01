module OrderHeader
  class RenameCustomer
    def call(event)
      Customer.find_by(customer_id: event.data.fetch(:customer_id)).update!(name: event.data.fetch(:name))
      Header.where(customer_id: event.data.fetch(:customer_id)).update_all(customer: event.data.fetch(:name))
    end
  end
end
