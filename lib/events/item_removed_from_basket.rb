module Events
  class ItemRemovedFromBasket < RailsEventStore::Event
    def order_id
      @data.fetch(:order_id)
    end

    def product_id
      @data.fetch(:product_id)
    end

    def self.create(order_id, product_id)
      new(data: {order_id: order_id, product_id: product_id})
    end
  end
end
