require 'test_helper'

module Pricing
  module Discounts
    class OrderTest < ActiveSupport::TestCase

      cover 'Pricing::Discounts*'

      def setup
        @order = Order.new
      end

      def test_can_be_discounted
        @order.discount
      end
    end

    class DiscountedOrderTest < ActiveSupport::TestCase
      cover 'Pricing::Discounts*'

      def test_can_change_its_discount_value
        @order = Order.new
        @order.discount.change_discount
      end

      def test_can_change_many_times
        Order.new.discount.change_discount.change_discount
      end

      def test_can_reset_discount
        Order.new.discount.reset
      end
    end

    class OrderWithClearedDiscount < ActiveSupport::TestCase
      cover 'Pricing::Discounts*'

      def test_can_be_discounted_again
        Order.new.discount.reset.discount
      end
    end

    class PercentageDiscountTest < ActiveSupport::TestCase
      cover 'Pricing::Discounts*'

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
    end
  end
end
