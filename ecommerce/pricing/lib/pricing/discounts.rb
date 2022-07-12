module Pricing
  module Discounts
    class UnacceptableDiscountRange < StandardError
    end

    class PercentageDiscount
      attr_reader :value

      def initialize(value)
        raise UnacceptableDiscountRange if value <= 0
        raise UnacceptableDiscountRange if value > 100

        @value = value
      end

      def apply(total)
        total - discount(total)
      end

      def discount(total)
        total * value / 100
      end

      def add(other_discount)
        new_value = [value + other_discount.value, 100].min

        PercentageDiscount.new(new_value)
      end
    end

    class NoPercentageDiscount
      def apply(total)
        total
      end

      def discount(_)
        0
      end

      def add(other_discount)
        other_discount
      end

      def value
        0
      end
    end
  end
end
