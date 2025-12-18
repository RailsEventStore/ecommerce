require "infra"
require_relative "pricing/discounts"
require_relative "pricing/coupon"
require_relative "pricing/commands"
require_relative "pricing/events"
require_relative "pricing/services"
require_relative "pricing/offer"
require_relative "pricing/price_change"
require_relative "pricing/time_promotion"

module Pricing

  class Configuration
    def call(event_store, command_bus)

      command_bus.register(
        DraftOffer,
        DraftOfferHandler.new(event_store)
      )
      command_bus.register(
        AddPriceItem,
        OnAddItemToBasket.new(event_store)
      )
      command_bus.register(
        RemovePriceItem,
        OnRemoveItemFromBasket.new(event_store)
      )
      command_bus.register(
        SetPrice,
        SetPriceHandler.new(event_store)
      )
      command_bus.register(
        SetFuturePrice,
        SetFuturePriceHandler.new(event_store)
      )
      command_bus.register(
        SetPercentageDiscount,
        SetPercentageDiscountHandler.new(event_store)
      )
      command_bus.register(
        RemovePercentageDiscount,
        RemovePercentageDiscountHandler.new(event_store)
      )
      command_bus.register(
        ChangePercentageDiscount,
        ChangePercentageDiscountHandler.new(event_store)
      )
      command_bus.register(
        RegisterCoupon,
        OnCouponRegister.new(event_store)
      )
      command_bus.register(
        CreateTimePromotion,
        CreateTimePromotionHandler.new(event_store)
      )
      command_bus.register(
        MakeProductFreeForOrder,
        MakeProductFreeForOrderHandler.new(event_store)
      )
      command_bus.register(
        RemoveFreeProductFromOrder,
        RemoveFreeProductFromOrderHandler.new(event_store)
      )
      command_bus.register(
        UseCoupon,
        UseCouponHandler.new(event_store)
      )
      command_bus.register(
        AcceptOffer,
        OnAcceptOffer.new(event_store)
      )
      command_bus.register(
        RejectOffer,
        OnRejectOffer.new(event_store)
      )
      command_bus.register(
        ExpireOffer,
        OnExpireOffer.new(event_store)
      )
      command_bus.register(
        SetTimePromotionDiscount,
        SetTimePromotionDiscountHandler.new(event_store)
      )
      command_bus.register(
        RemoveTimePromotionDiscount,
        RemoveTimePromotionDiscountHandler.new(event_store)
      )
    end
  end
end
