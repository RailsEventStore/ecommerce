module Pricing
  class Product
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def set_price(price)
      apply(PriceSet.new(data: { product_id: @id, price: price }))
    end

    def set_future_price(price, valid_at)
      apply(FuturePriceSet.new(data: { product_id: @id, price: price, valid_since: valid_at }))
    end

    private

    on(PriceSet) { |_| }

    on(FuturePriceSet) { |_| }
  end
end
