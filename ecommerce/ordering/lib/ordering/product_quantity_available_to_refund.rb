module Ordering
  class ProductQuantityAvailableToRefund
    def self.call(order_id, product_id)
      RubyEventStore::Projection
        .from_stream("Ordering::Order$#{order_id}")
        .init(-> { { available: 0 } })
        .when(ItemAddedToBasket, -> (state, event) { state[:available] += 1 if event.data.fetch(:product_id) == product_id })
        .when(ItemRemovedFromBasket, -> (state, event) { state[:available] -= 1 if event.data.fetch(:product_id) == product_id })
    end
  end
end
