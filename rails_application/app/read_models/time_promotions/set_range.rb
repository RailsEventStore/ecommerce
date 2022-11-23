module TimePromotions
  class SetRange < Infra::EventHandler
    def call(event)
      TimePromotion.find_by(id: event.data[:time_promotion_id]).update!(start_time: event.data[:start_time], end_time: event.data[:end_time])
    end
  end
end
