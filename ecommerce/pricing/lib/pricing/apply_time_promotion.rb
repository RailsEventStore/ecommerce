module Pricing
  class ApplyTimePromotion

    def initialize(command_bus, event_store)
      @command_bus = command_bus
      @event_store = event_store
    end

    def call(event)
      discount = PromotionsCalendar.new(@event_store).current_time_promotions_discount

      if discount.exists?
        @command_bus.(SetTimePromotionDiscount.new(order_id: event.data.fetch(:order_id), amount: discount.value))
      else
        @command_bus.(RemoveTimePromotionDiscount.new(order_id: event.data.fetch(:order_id)))
      end

    rescue NotPossibleToAssignDiscountTwice, NotPossibleToRemoveWithoutDiscount
    end

    private
  end
end
