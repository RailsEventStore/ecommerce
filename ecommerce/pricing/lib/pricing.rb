require "infra"
require "math"
require_relative "pricing/discounts"
require_relative "pricing/coupon"
require_relative "pricing/commands"
require_relative "pricing/events"
require_relative "pricing/services"
require_relative "pricing/order"
require_relative "pricing/product"
require_relative "pricing/pricing_catalog"
require_relative "pricing/time_promotion"
require_relative "pricing/promotions_calendar"

module Pricing
  class Configuration
    def call(cqrs)
      cqrs.register_command(
        AddPriceItem,
        OnAddItemToBasket.new(cqrs.event_store)
      )
      cqrs.register_command(
        RemovePriceItem,
        OnRemoveItemFromBasket.new(cqrs.event_store)
      )
      cqrs.register_command(
        SetPrice,
        SetPriceHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        CalculateTotalValue,
        OnCalculateTotalValue.new(cqrs.event_store)
      )
      cqrs.register_command(
        CalculateSubAmounts,
        OnCalculateTotalValue.new(cqrs.event_store).public_method(:calculate_sub_amounts)
      )
      cqrs.register_command(
        SetPercentageDiscount,
        SetPercentageDiscountHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        ResetPercentageDiscount,
        ResetPercentageDiscountHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        ChangePercentageDiscount,
        ChangePercentageDiscountHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        RegisterCoupon,
        OnCouponRegister.new(cqrs.event_store)
      )
      cqrs.register_command(
        CreateTimePromotion,
        CreateTimePromotionHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        LabelTimePromotion,
        LabelTimePromotionHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        SetTimePromotionDiscount,
        SetTimePromotionDiscountHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        SetTimePromotionRange,
        SetTimePromotionRangeHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        MakeProductFreeForOrder,
        MakeProductFreeForOrderHandler.new(cqrs.event_store)
      )
      cqrs.register_command(
        RemoveFreeProductFromOrder,
        RemoveFreeProductFromOrderHandler.new(cqrs.event_store)
      )
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::CalculateTotalValue.new(
              order_id: event.data.fetch(:order_id)
            )
          )
        end,
        [
          PriceItemAdded,
          PriceItemRemoved,
          PercentageDiscountSet,
          PercentageDiscountReset,
          PercentageDiscountChanged,
          ProductMadeFreeForOrder,
          FreeProductRemovedFromOrder
        ]
      )
    end
  end
end
