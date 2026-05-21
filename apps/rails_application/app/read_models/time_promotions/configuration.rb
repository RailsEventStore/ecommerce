module TimePromotions
  class TimePromotion < ApplicationRecord
    self.table_name = "time_promotions"
  end

  private_constant :TimePromotion

  def self.time_promotions_for_store(store_id)
    TimePromotion.where(store_id: store_id)
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateTimePromotion.new, to: [Pricing::TimePromotionCreated])
      event_store.subscribe(AssignStoreToTimePromotion.new, to: [Stores::TimePromotionRegistered])
    end
  end
end
