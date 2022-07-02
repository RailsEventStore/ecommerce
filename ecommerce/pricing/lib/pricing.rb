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
require_relative "pricing/happy_hour"
require_relative "pricing/helpers/happy_hours_for_product"

module Pricing
  class Configuration
    def call(cqrs)
      cqrs.register_command(
        AddPriceItem,
        OnAddItemToBasket.new(cqrs.event_store),
        PriceItemAdded
      )
      cqrs.register_command(
        RemovePriceItem,
        OnRemoveItemFromBasket.new(cqrs.event_store),
        PriceItemRemoved
      )
      cqrs.register_command(
        SetPrice,
        SetPriceHandler.new(cqrs.event_store),
        PriceSet
      )
      cqrs.register_command(
        CalculateTotalValue,
        OnCalculateTotalValue.new(cqrs.event_store),
        OrderTotalValueCalculated
      )
      cqrs.register_command(
        CalculateSubAmounts,
        OnCalculateTotalValue.new(cqrs.event_store).public_method(:calculate_sub_amounts),
        PriceItemValueCalculated
      )
      cqrs.register_command(
        SetPercentageDiscount,
        SetPercentageDiscountHandler.new(cqrs.event_store),
        PercentageDiscountSet
      )
      cqrs.register_command(
        ResetPercentageDiscount,
        ResetPercentageDiscountHandler.new(cqrs.event_store),
        PercentageDiscountReset
      )
      cqrs.register_command(
        ChangePercentageDiscount,
        ChangePercentageDiscountHandler.new(cqrs.event_store),
        PercentageDiscountChanged
      )
      cqrs.register_command(
        RegisterCoupon,
        OnCouponRegister.new(cqrs.event_store),
        CouponRegistered
      )
      cqrs.register_command(
        CreateHappyHour,
        CreateHappyHourHandler.new(cqrs.event_store),
        HappyHourCreated
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
          PercentageDiscountChanged
        ]
      )
    end
  end
end
