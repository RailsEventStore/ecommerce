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

    private

    def create_time_promotion(event)
      id = event.data[:time_promotion_id]

      TimePromotion.create!(event.data.slice(:code).merge(id: id))
    end

    def label(event)
      id = event.data[:time_promotion_id]

      TimePromotion.find_by(id: id).update!(label: event.data[:label])
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
