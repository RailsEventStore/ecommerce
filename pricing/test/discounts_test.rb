require 'test_helper'

module Pricing
  module Discounts
    class EmptyOrderTest < ActiveSupport::TestCase

      cover 'Pricing::Discounts*'

      def setup
        @order = EmptyOrder.new
      end

      def test_can_be_discounted
        @order.discount(PercentageDiscount.new(10))
      end
    end

    class DiscountedOrderTest < ActiveSupport::TestCase
      def test_can_change_its_discount_value
        skip
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

    class EmptyOrder
      def discount(discount)
      end
    end
  end
end
