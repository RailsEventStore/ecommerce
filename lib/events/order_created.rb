module Events
  class OrderCreated < RailsEventStore::Event
    def order_id
      @data.fetch(:order_id)
    end

    def order_number
      @data.fetch(:order_number)
    end

    def customer_id
      @data.fetch(:customer_id)
    end

    def self.create(order_id, order_number, customer_id)
      new(data: {order_id: order_id, order_number: order_number, customer_id: customer_id})
    end
  end
end
