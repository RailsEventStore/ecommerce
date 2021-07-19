require 'test_helper'

module Pricing
  module Discounts
    class OrderTest < ActiveSupport::TestCase

      cover 'Pricing::Discounts*'

      def setup
        @order = Order.new
      end

      def test_can_be_discounted
        @order.discount(PercentageDiscount.new(10))
      end
    end

    class DiscountedOrderTest < ActiveSupport::TestCase
      def test_can_change_its_discount_value
        @order = Order.new
        @order.discount(PercentageDiscount.new(10)).change_discount(PercentageDiscount.new(15))
      end

      def test_can_reset_discount
        discount = PercentageDiscount.new(10)
        Order.new.discount(discount).reset
      end
    end

    class OrderWithClearedDiscount < ActiveSupport::TestCase
      def test_can_be_discounted_again
        _10_percent = PercentageDiscount.new(10)
        Order.new.discount(_10_percent).reset.discount(_10_percent)
      end
    end

    class PercentageDiscountTest < ActiveSupport::TestCase
      def test_is_more_than_zero
        assert_raises UnacceptableDiscountRange do
          PercentageDiscount.new(0)
        end
      end

      def test_is_not_more_than_100_percent
        assert_raises UnacceptableDiscountRange do
          PercentageDiscount.new(100.01)
        end
      end
    end
  end
end
