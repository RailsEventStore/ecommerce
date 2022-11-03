module Processes
  class SyncShipmentFromOrdering
    def initialize(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::ItemAddedToBasket, [:order_id, :product_id],
                          Shipping::AddItemToShipmentPickingList, [:order_id, :product_id])
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::ItemRemovedFromBasket, [:order_id, :product_id],
                          Shipping::RemoveItemFromShipmentPickingList, [:order_id, :product_id])
    end
  end
end