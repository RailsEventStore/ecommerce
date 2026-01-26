module Crm
  class Order
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def set_customer(customer_id)
      return if @customer_id == customer_id
      apply CustomerAssignedToOrder.new(data: { order_id: @id, customer_id: customer_id })
    end

    private

    on CustomerAssignedToOrder do |event|
      @customer_id = event.data[:customer_id]
    end
  end
end
