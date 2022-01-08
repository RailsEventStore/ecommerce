module Pricing
  module Discounts
    class UnacceptableDiscountRange < StandardError
    end

    class PercentageDiscount
      def initialize(value)
        raise UnacceptableDiscountRange if value <= 0
        raise UnacceptableDiscountRange if value > 100

        @value = value
      end

      def apply(total)
        total - discount(total)
      end

      def discount(total)
        total * @value / 100
      end
    end

    class NoPercentageDiscount
      def apply(total)
        total
      end

      def discount(total)
        0
      end
    end

    class Order
      def discount
        DiscountedOrder.new
      end
    end

    class DiscountedOrder
      def change_discount
        DiscountedOrder.new
      end

      def reset
        Order.new
      end
    end
  end
end
