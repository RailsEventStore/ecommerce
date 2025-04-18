require_relative "test_helper"

module Pricing
  module Discounts

    class PercentageDiscountTest < Test
      cover "Pricing::Discounts*"

      def test_is_more_than_zero
        assert_raises UnacceptableDiscountRange do
          PercentageDiscount.new(0)
        end
      end

      def test_is_not_lower_than_0
        assert_raises UnacceptableDiscountRange do
          PercentageDiscount.new(-0.01)
        end
      end

      def test_is_not_more_than_100_percent
        assert_raises UnacceptableDiscountRange do
          PercentageDiscount.new(100.01)
        end
      end

      def test_100_is_ok
        PercentageDiscount.new(100)
      end

      def test_0_01_is_ok
        PercentageDiscount.new(0.01)
      end

      def test_applies_to_value
        assert_equal(90, PercentageDiscount.new(10).apply(100))
      end

      def test_calculates_floats_too
        assert_equal(90.45, PercentageDiscount.new(10).apply(100.50))
      end

      def test_can_add_another_discount
        first_discount = PercentageDiscount.new(20)
        second_discount = PercentageDiscount.new(15)
        combined = first_discount.add(second_discount)

        assert_equal(65, combined.apply(100))
      end

      def test_cannot_add_to_more_than_100
        first_discount = PercentageDiscount.new(50)
        second_discount = PercentageDiscount.new(65)
        combined = first_discount.add(second_discount)

        assert_equal(0, combined.apply(100))
      end
    end

    class NoPercentageDiscountTest < Test
      cover "Pricing::Discounts*"

      def test_doesnt_change_total
        assert_equal(100, NoPercentageDiscount.new.apply(100))
      end
    end

    class ThreePlusOneGratisTest < Test
      cover "Pricing::Discounts*"
      def setup
        @three_plus_one_gratis = ThreePlusOneGratis.new
        @product_id = SecureRandom.uuid
      end

      def test_returns_full_price_when_product_not_found
        result = @three_plus_one_gratis.apply([], @product_id, 20)
        assert_equal [false, 20], result
      end

      def test_returns_full_price_when_quantity_plus_one_is_less_than_4
        quantities = [{ product_id: @product_id, quantity: 2 }]
        result = @three_plus_one_gratis.apply(quantities, @product_id, 20)
        assert_equal [false, 20], result
      end

      def test_returns_free_when_quantity_plus_one_is_4
        quantities = [{ product_id: @product_id, quantity: 3 }]
        result = @three_plus_one_gratis.apply(quantities, @product_id, 20)
        assert_equal [true, 0], result
      end

      def test_returns_full_price_when_quantity_plus_one_is_5
        quantities = [{ product_id: @product_id, quantity: 4 }]
        result = @three_plus_one_gratis.apply(quantities, @product_id, 20)
        assert_equal [false, 20], result
      end

      def test_returns_free_when_quantity_plus_one_is_8
        quantities = [{ product_id: @product_id, quantity: 7 }]
        result = @three_plus_one_gratis.apply(quantities, @product_id, 20)
        assert_equal [true, 0], result
      end

      def test_returns_full_price_when_quantity_plus_one_is_9
        quantities = [{ product_id: @product_id, quantity: 8 }]
        result = @three_plus_one_gratis.apply(quantities, @product_id, 20)
        assert_equal [false, 20], result
      end

      def test_does_not_confuse_other_product_ids
        other_product_id = SecureRandom.uuid
        quantities = [{ product_id: other_product_id, quantity: 3 }]
        result = @three_plus_one_gratis.apply(quantities, @product_id, 20)
        assert_equal [false, 20], result
      end
    end
  end
end
