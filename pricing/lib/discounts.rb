module Pricing
  module Discounts
    class UnacceptableDiscountRange < StandardError; end

    class PercentageDiscount
      def initialize(value)
        raise UnacceptableDiscountRange if value <= 0
        raise UnacceptableDiscountRange if value > 100
      end
    end
  end
end