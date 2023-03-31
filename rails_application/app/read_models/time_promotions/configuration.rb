module TimePromotions
  class TimePromotion < ApplicationRecord
    self.table_name = "time_promotions"

    scope :current, -> { where("start_time < ? AND end_time > ?", Time.current, Time.current) }
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateTimePromotion, to: [Pricing::TimePromotionCreated])
    end
  end
end
