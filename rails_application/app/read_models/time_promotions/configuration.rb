module TimePromotions
  class TimePromotion < ApplicationRecord
    self.table_name = "time_promotions"

    scope :current, -> { where("start_time < ? AND end_time > ?", DateTime.now, DateTime.now) }
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateTimePromotion, to: [Pricing::TimePromotionCreated])
      event_store.subscribe(LabelTimePromotion, to: [Pricing::TimePromotionLabeled])
      event_store.subscribe(SetDiscount, to: [Pricing::TimePromotionDiscountSet])
      event_store.subscribe(SetRange, to: [Pricing::TimePromotionRangeSet])
    end
  end
end
