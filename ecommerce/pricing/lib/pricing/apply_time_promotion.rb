module Pricing
  class ApplyTimePromotion
    def call(event)
      discount = PromotionsCalendar.new(event_store).current_time_promotions_discount

      if discount.exists?
        command_bus.(SetTimePromotionDiscount.new(order_id: event.data.fetch(:order_id), amount: discount.value))
      else
        command_bus.(ResetTimePromotionDiscount.new(order_id: event.data.fetch(:order_id)))
      end
    end

    private

    def command_bus
      Pricing.command_bus
    end

    def event_store
      Pricing.event_store
    end
  end
end
