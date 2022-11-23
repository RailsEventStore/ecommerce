module TimePromotions
  class SetDiscount < Infra::EventHandler
    def call(event)
      TimePromotion.find_by(id: event.data[:time_promotion_id]).update!(discount: event.data[:discount])
    end
  end
end
