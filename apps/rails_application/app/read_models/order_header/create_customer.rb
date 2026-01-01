module OrderHeader
  class CreateCustomer
    def call(event)
      Customer.create!(
        customer_id: event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )
    end
  end
end
