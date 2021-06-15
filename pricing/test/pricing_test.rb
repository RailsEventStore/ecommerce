require 'test_helper'

module Pricing
  class PricingTest < ActiveSupport::TestCase

    cover 'Pricing*'

    def test_setting_price_updates_read_model
      product_1  = ProductCatalog::Product.create(name: 'test')

      set_price(product_1, 20)
      assert_product_read_model_price(product_1, 20)
      set_price(product_1, 40)
      assert_product_read_model_price(product_1, 40)
    end

    private

    def assert_product_read_model_price(product_1, amount)
      assert_equal(amount, ProductCatalog::Product.find_by(id: product_1.id).price)
    end

    def set_price(product_1, amount)
      run_command(SetPrice.new(product_id: product_1.id, price: amount))
    end
  end
end

