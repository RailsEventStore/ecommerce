module TimePromotions
  class LabelTimePromotion < Infra::EventHandler
    def call(event)
      TimePromotion.find_by(id: event.data[:time_promotion_id]).update!(label: event.data[:label])
    end
  end
end
