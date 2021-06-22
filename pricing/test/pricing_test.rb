require 'test_helper'

module Pricing
  class PricingTest < ActiveSupport::TestCase

    cover 'Pricing*'

    def test_setting_price_updates_read_model
      product_1_id  = run_command(ProductCatalog::RegisterProduct.new(product_uid: SecureRandom.uuid, name: "test"))

      set_price(product_1_id, 20)
      assert_product_read_model_price(product_1_id, 20)
      set_price(product_1_id, 40)
      assert_product_read_model_price(product_1_id, 40)
    end

    private

    def assert_product_read_model_price(product_id, amount)
      assert_equal(amount, ProductCatalog::Product.find_by(id: product_id).price)
    end

    def set_price(product_id, amount)
      run_command(SetPrice.new(product_id: product_id, price: amount))
    end
  end
end

