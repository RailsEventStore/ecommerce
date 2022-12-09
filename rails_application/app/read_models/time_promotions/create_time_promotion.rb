module TimePromotions
  class CreateTimePromotion < Infra::EventHandler
    def call(event)
      TimePromotion.create!(event.data.slice(:code, :discount, :start_time, :end_time, :label).merge(id: event.data[:time_promotion_id]))
    end
  end
end
