module Processes
  class SyncPricingFromOrdering
    def initialize(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
             .call(Ordering::ItemAddedToBasket, [:order_id, :product_id],
                   Pricing::AddPriceItem, [:order_id, :product_id])

      Infra::Process.new(event_store, command_bus)
             .call(Ordering::ItemRemovedFromBasket, [:order_id, :product_id],
                   Pricing::RemovePriceItem, [:order_id, :product_id])

      Infra::Process.new(event_store, command_bus)
             .call(Ordering::OrderSubmitted, [:order_id],
                   Pricing::CalculateTotalValue, [:order_id])

      Infra::Process.new(event_store, command_bus)
             .call(Ordering::OrderSubmitted, [:order_id],
                   Pricing::CalculateSubAmounts, [:order_id])
    end
  end
end