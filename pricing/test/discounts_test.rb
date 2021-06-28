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
      def test_is_at_least_1_percent
        skip
      end

      def test_is_not_more_than_100_percent
        skip
      end
    end

    class EmptyOrder
      def discount(discount)
      end
    end

    class PercentageDiscount
      def initialize(percentage_amount)
      end
    end
  end
end
