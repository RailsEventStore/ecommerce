module Processes
  class ApplyTimePromotion

    def initialize(command_bus, event_store, order_repository = Orders)
      @command_bus = command_bus
      @event_store = event_store
      @order_repository = order_repository
    end

    def call(event)
      order_id = event.data.fetch(:order_id)
      store_id = @order_repository.store_id_for_order(order_id)
      return unless store_id

      discount = PromotionsCalendar.new(@event_store, store_id).current_time_promotions_discount

      if discount.exists?
        @command_bus.(Pricing::SetTimePromotionDiscount.new(order_id: order_id, amount: discount.value))
      else
        @command_bus.(Pricing::RemoveTimePromotionDiscount.new(order_id: order_id))
      end

    rescue Pricing::NotPossibleToAssignDiscountTwice, Pricing::NotPossibleToRemoveWithoutDiscount
    end

    private
  end
end
