module Processes
  class SyncShipmentFromPricing
    def initialize(event_store, command_bus)
      event_store.subscribe(
        ->(event) do
          command_bus.call(
            Shipping::AddItemToShipmentPickingList.new(
              event.data.fetch(:order_id),
              event.data.fetch(:product_id)
            )
          )
        end,
        to: [Pricing::PriceItemAdded]
      )
      event_store.subscribe(
        ->(event) do
          command_bus.call(
            Shipping::RemoveItemFromShipmentPickingList.new(
              event.data.fetch(:order_id),
              event.data.fetch(:product_id)
            )
          )
        end,
        to: [Pricing::PriceItemRemoved]
      )
    end
  end
end
