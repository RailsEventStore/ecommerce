module Pricing
  class PriceChange
    include AggregateRoot

    def initialize(product_id)
      @product_id = product_id
    end

    def set_price(price)
      apply(PriceSet.new(data: { product_id: @product_id, price: price }))
    end

    private

    on(PriceSet) { |_| }
  end
end
