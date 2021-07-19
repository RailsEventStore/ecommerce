module Pricing
  module Discounts
    class UnacceptableDiscountRange < StandardError; end

    class PercentageDiscount
      def initialize(value)
        raise UnacceptableDiscountRange if value <= 0
        raise UnacceptableDiscountRange if value > 100
      end
    end

    class Order
      def discount(discount)
        DiscountedOrder.new(discount)
      end
    end

    class DiscountedOrder
      def initialize(discount)
      end

      def change_discount(new_discount)
        DiscountedOrder.new(new_discount)
      end

      def reset
        Order.new
      end
    end
  end


end