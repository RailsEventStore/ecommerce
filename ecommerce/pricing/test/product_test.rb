require_relative "test_helper"

module Pricing
  class ProductTest < Test
    cover "Pricing::Product*"

    def test_product_price_is_set
      product_id = SecureRandom.uuid

      set_price(product_id, 20)
    end

    private

    def set_price(product_id, amount)
      run_command(SetPrice.new(product_id: product_id, price: amount))
    end
  end
end
