module Processes
  class ApplyTimePromotion < Infra::ProcessManager

    subscribes_to(
      Stores::OfferRegistered,
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::PercentageDiscountSet,
      Pricing::PercentageDiscountRemoved,
      Pricing::PercentageDiscountChanged,
      Pricing::ProductMadeFreeForOrder,
      Pricing::FreeProductRemovedFromOrder
    )

    private

    def initial_state
      ProcessState.new
    end

    def act
      return unless state.store_id

      discount = PromotionsCalendar.new(event_store, state.store_id).current_time_promotions_discount

      if discount.exists?
        command_bus.call(Pricing::SetTimePromotionDiscount.new(order_id: id, amount: discount.value))
      else
        command_bus.call(Pricing::RemoveTimePromotionDiscount.new(order_id: id))
      end
    rescue Pricing::NotPossibleToAssignDiscountTwice, Pricing::NotPossibleToRemoveWithoutDiscount
    end

    def apply(event)
      case event
      when Stores::OfferRegistered
        state.with(store_id: event.data.fetch(:store_id))
      else
        state
      end
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:store_id) do
      def initialize(store_id: nil) = super
    end
  end
end
