module ClientOrders
  class CreateTimePromotion
    def call(event)
      TimePromotion.create!(
        event.data.slice(:discount, :start_time, :end_time, :label).merge(id: event.data.fetch(:time_promotion_id))
      )
    end
  end
end
