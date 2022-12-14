require "infra"
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
require_relative "pricing/increase_order_price"
require_relative "pricing/reduce_order_total_value"
require_relative "pricing/calculate_order_sub_amounts_value"
require_relative "pricing/calculate_order_total_value"

require_relative "../../ordering/lib/ordering/events/item_added_to_basket"
require_relative "../../ordering/lib/ordering/events/item_removed_from_basket"
require_relative "../../ordering/lib/ordering/events/order_submitted"

module Pricing
  class Configuration
    def call(event_store, command_bus)
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
        CalculateTotalValue,
        OnCalculateTotalValue.new(event_store)
      )
      command_bus.register(
        CalculateSubAmounts,
        OnCalculateTotalValue.new(event_store).public_method(:calculate_sub_amounts)
      )
      command_bus.register(
        SetPercentageDiscount,
        SetPercentageDiscountHandler.new(event_store)
      )
      command_bus.register(
        ResetPercentageDiscount,
        ResetPercentageDiscountHandler.new(event_store)
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
      event_store.subscribe(IncreaseOrderPrice.new(command_bus), to: [Ordering::ItemAddedToBasket])

      event_store.subscribe(ReduceOrderTotalValue.new(command_bus), to: [Ordering::ItemRemovedFromBasket])

      event_store.subscribe(CalculateOrderTotalValue.new(command_bus), to: [
        Ordering::OrderSubmitted,
        PriceItemAdded,
        PriceItemRemoved,
        PercentageDiscountSet,
        PercentageDiscountReset,
        PercentageDiscountChanged,
        ProductMadeFreeForOrder,
        FreeProductRemovedFromOrder
      ])

      event_store.subscribe(CalculateOrderTotalSubAmountsValue.new(command_bus), to: [Ordering::OrderSubmitted])
    end
  end
end
