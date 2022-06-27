require_relative "test_helper"

module Pricing
  class ProductTest < Test
    cover "Pricing::Product*"

    def test_product_price_is_set
      product_id = SecureRandom.uuid

      set_price(product_id, 20)
    end

    def test_product_happy_hour_is_created
      product_id = SecureRandom.uuid
      discount_in_percent = 30
      start_hour = 15
      end_hour = 18

      add_product_to_happy_hour(product_id, discount_in_percent, start_hour, end_hour)
    end

    def test_can_add_more_happy_hours
      product_id = SecureRandom.uuid

      add_product_to_happy_hour(product_id, 50, 12, 15)
      add_product_to_happy_hour(product_id, 30, 15, 18)
      add_product_to_happy_hour(product_id, 10, 18, 20)
    end

    def test_cannot_add_overlapping_happy_hours
      product_id = SecureRandom.uuid

      add_product_to_happy_hour(product_id, 50, 12, 15)

      assert_raises Pricing::Product::OverlappingHappyHour do
        add_product_to_happy_hour(product_id, 50, 13, 16)
      end

      add_product_to_happy_hour(product_id, 30, 15, 18)

      assert_raises Pricing::Product::OverlappingHappyHour do
        add_product_to_happy_hour(product_id, 50, 12, 15)
      end
    end

    private

    def set_price(product_id, amount)
      run_command(SetPrice.new(product_id: product_id, price: amount))
    end

    def add_product_to_happy_hour(product_id, discount, start_hour, end_hour)
      run_command(
        AddProductToHappyHour.new(
          product_id: product_id,
          discount: discount,
          start_hour: start_hour,
          end_hour: end_hour
        )
      )
    end
  end
end
