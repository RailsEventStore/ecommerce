module Events
  class OrderExpired < RailsEventStore::Event
    def order_id
      @data.fetch(:order_id)
    end

    def self.create(order_id)
      new(data: {order_id: order_id})
    end
  end
end
