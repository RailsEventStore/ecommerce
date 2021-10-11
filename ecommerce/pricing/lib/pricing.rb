require "infra"
require_relative "pricing/discounts"
require_relative "pricing/commands"
require_relative "pricing/events"
require_relative "pricing/services"
require_relative "pricing/order"
require_relative "pricing/product"
require_relative "pricing/pricing_catalog"

module Pricing
  class Configuration
    def call(cqrs)
      cqrs.register_command(
        AddItemToBasket,
        OnAddItemToBasket.new(cqrs.event_store),
        ItemAddedToBasket
      )
      cqrs.register_command(
        RemoveItemFromBasket,
        OnRemoveItemFromBasket.new(cqrs.event_store),
        ItemRemovedFromBasket
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
        SetPercentageDiscount,
        SetPercentageDiscountHandler.new(cqrs.event_store),
        PercentageDiscountSet
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
          ItemAddedToBasket,
          ItemRemovedFromBasket,
          Pricing::PercentageDiscountSet
        ]
      )
    end
  end
end
