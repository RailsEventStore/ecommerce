module Processes
  class SyncPricingFromOrdering
    def initialize(cqrs)
      sync_basket_with_pricing(cqrs)
      calculate_total_value_when_order_submitted(cqrs)
      calculate_sub_amounts_when_order_submitted(cqrs)
    end

    private

    def sync_basket_with_pricing(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::AddPriceItem.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemAddedToBasket]
      )

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::RemovePriceItem.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemRemovedFromBasket]
      )
    end


    def calculate_total_value_when_order_submitted(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::CalculateTotalValue.new(
              order_id: event.data.fetch(:order_id)
            )
          )
        end,
        [Ordering::OrderSubmitted]
      )
    end

    def calculate_sub_amounts_when_order_submitted(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::CalculateSubAmounts.new(
              order_id: event.data.fetch(:order_id)
            )
          )
        end,
        [Ordering::OrderSubmitted]
      )
    end

  end
end