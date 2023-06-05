require_relative "test_helper"

module Pricing
  class ProductTest < Test
    cover "Pricing::Product*"

    def test_product_price_is_set
      product_id = SecureRandom.uuid

      set_price(product_id, 20)
    end

    def test_set_future_price
      product_id = SecureRandom.uuid
      valid_since = 2.days.from_now
      price = 20

      future_price_set = [
        PriceSet.new(data: { product_id: product_id, price: price }),
      ]

      assert_events("Pricing::PriceChange$#{product_id}", *future_price_set) do
        set_future_price(product_id, price, valid_since)
      end
    end

    private

    def set_price(product_id, amount)
      run_command(SetPrice.new(product_id: product_id, price: amount))
    end
  end
end
