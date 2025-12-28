module TimePromotions
  class TimePromotion < ApplicationRecord
    self.table_name = "time_promotions"

    scope :current, -> { where("start_time < ? AND end_time > ?", Time.current, Time.current) }
  end

  private_constant :TimePromotion

  def self.time_promotions_for_store(store_id)
    TimePromotion.where(store_id: store_id)
  end

  def self.current_time_promotions_for_store(store_id)
    TimePromotion.where(store_id: store_id).current
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateTimePromotion, to: [Pricing::TimePromotionCreated])
      event_store.subscribe(AssignStoreToTimePromotion.new, to: [Stores::TimePromotionRegistered])
    end
  end
end
