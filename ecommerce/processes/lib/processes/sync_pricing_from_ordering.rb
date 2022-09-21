module Processes
  class SyncPricingFromOrdering
    def initialize(cqrs)
      cqrs.process(
        Ordering::ItemAddedToBasket, [:order_id, :product_id],
        Pricing::AddPriceItem,       [:order_id, :product_id]
      )
      cqrs.process(
        Ordering::ItemRemovedFromBasket, [:order_id, :product_id],
        Pricing::RemovePriceItem,        [:order_id, :product_id]
      )
      cqrs.process(
        Ordering::OrderSubmitted,     [:order_id],
        Pricing::CalculateTotalValue, [:order_id]
      )
      cqrs.process(
        Ordering::OrderSubmitted,     [:order_id],
        Pricing::CalculateSubAmounts, [:order_id]
      )
    end
  end
end