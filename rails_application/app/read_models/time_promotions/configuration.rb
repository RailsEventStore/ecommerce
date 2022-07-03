module TimePromotions
  class TimePromotion < ApplicationRecord
    self.table_name = "time_promotions"
  end

  class Configuration
    def call(cqrs)
      cqrs.subscribe(
        ->(event) { create_time_promotion(event) },
        [Pricing::TimePromotionCreated]
      )
      cqrs.subscribe(
        ->(event) { set_discount(event) },
        [Pricing::TimePromotionDiscountSet]
      )
      cqrs.subscribe(
        ->(event) { set_range(event) },
        [Pricing::TimePromotionRangeSet]
      )
    end

    private

    def create_time_promotion(event)
      id = event.data[:time_promotion_id]

      TimePromotion.create!(event.data.slice(:label, :code).merge(id: id))
    end

    def set_discount(event)
      id = event.data[:time_promotion_id]

      TimePromotion.find_by(id: id).update!(discount: event.data[:discount])
    end

    def set_range(event)
      id = event.data[:time_promotion_id]

      TimePromotion.find_by(id: id).update!(start_time: event.data[:start_time], end_time: event.data[:end_time])
    end
  end
end
