module Processes
  class SyncShipmentFromPricing
    def initialize(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
                    .call(Pricing::PriceItemAdded, [:order_id, :product_id],
                          Shipping::AddItemToShipmentPickingList, [:order_id, :product_id])
      Infra::Process.new(event_store, command_bus)
                    .call(Pricing::PriceItemRemoved, [:order_id, :product_id],
                          Shipping::RemoveItemFromShipmentPickingList, [:order_id, :product_id])
    end
  end
end