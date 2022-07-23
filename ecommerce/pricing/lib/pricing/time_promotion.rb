module Pricing
  class TimePromotion
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def create(label:)
      apply TimePromotionCreated.new(
        data: {
          time_promotion_id: @id,
          label: label
        }
      )
    end

    def set_discount(discount:)
      apply TimePromotionDiscountSet.new(
        data: {
          time_promotion_id: @id,
          discount: discount
        }
      )
    end

    def set_range(start_time:, end_time:)
      apply TimePromotionRangeSet.new(
        data: {
          time_promotion_id: @id,
          start_time: start_time,
          end_time: end_time
        }
      )
    end

    private

    on TimePromotionCreated do |_|
    end

    on TimePromotionDiscountSet do |_|
    end

    on TimePromotionRangeSet do |_|
    end
  end
end
