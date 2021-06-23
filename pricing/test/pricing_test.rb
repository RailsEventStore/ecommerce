require 'test_helper'

module Pricing
  class PricingTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Pricing*'

    def test_setting_price_updates_read_model
      product_1_id  = run_command(ProductCatalog::RegisterProduct.new(product_uid: SecureRandom.uuid, name: "test"))

      set_price(product_1_id, 20)
      assert_product_read_model_price(product_1_id, 20)
      set_price(product_1_id, 40)
      assert_product_read_model_price(product_1_id, 40)
    end

    def test_calculates_total_value
      set_price(1, 20)
      set_price(2, 30)
      set_price(3, 40)
      order_id = SecureRandom.uuid
      add_item(order_id, 1)
      add_item(order_id, 2)
      stream = "Pricing::Order$#{order_id}"
      assert_events(stream, OrderTotalValueCalculated.new(data: { order_id: order_id, amount: 50 })) do
        calculate_total_value(order_id)
      end

    end

    private

    def assert_product_read_model_price(product_id, amount)
      assert_equal(amount, ProductCatalog::Product.find_by(id: product_id).price)
    end

    def set_price(product_id, amount)
      run_command(SetPrice.new(product_id: product_id, price: amount))
    end

    def add_item(order_id, product_id)
      run_command(AddItemToBasket.new(order_id: order_id, product_id: product_id))
    end

    def calculate_total_value(order_id)
      run_command(CalculateTotalValue.new(order_id: order_id))
    end
  end
end

