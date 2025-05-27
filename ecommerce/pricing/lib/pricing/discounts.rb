module Pricing
  module Discounts
    GENERAL_DISCOUNT = "general_discount"
    TIME_PROMOTION_DISCOUNT = "time_promotion_discount"

    class UnacceptableDiscountRange < StandardError
    end

    class BasePriceNotProvided < StandardError
    end

    class Discount
      def self.build(discount)
        if discount.zero?
          NoPercentageDiscount.new
        else
          PercentageDiscount.new(discount)
        end
      end
    end

    class PercentageDiscount
      attr_reader :value, :type

      def initialize(type = GENERAL_DISCOUNT, value)
        raise UnacceptableDiscountRange if value <= 0
        raise UnacceptableDiscountRange if value > 100

        @type = type
        @value = value
      end

      def apply(total)
        total - discount(total)
      end

      def add(other_discount)
        new_value = [value + other_discount.value, 100].min

        PercentageDiscount.new(new_value)
      end

      def exists?
        true
      end

      private

      def discount(total)
        total * value / 100
      end
    end

    class NoPercentageDiscount
      def apply(total)
        total
      end

      def add(other_discount)
        other_discount
      end

      def exists?
      end
    end

    class ThreePlusOneGratis
      def apply(product_quantities, product_id, base_price)
        raise BasePriceNotProvided unless base_price
        product = product_quantities.find { |product_quantity| product_quantity.fetch(:product_id) == product_id }
        return [false, base_price] if product.nil?
        quantity = product.fetch(:quantity) + 1
        return [false, base_price] if !quantity.%(4).eql?(0)
        [true, 0]
      end
    end
  end
end
