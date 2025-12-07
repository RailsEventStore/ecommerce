module TimePromotions
  class AssignStoreToTimePromotion
    def call(event)
      TimePromotion.find(event.data.fetch(:time_promotion_id)).update!(store_id: event.data.fetch(:store_id))
    end
  end
end
