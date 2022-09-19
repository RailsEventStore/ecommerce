module Processes
  class SyncShipmentFromOrdering
    def initialize(cqrs)
      cqrs.process(
        Ordering::ItemAddedToBasket,            [:order_id, :product_id],
        Shipping::AddItemToShipmentPickingList, [:order_id, :product_id]
      )
      cqrs.process(
        Ordering::ItemRemovedFromBasket,             [:order_id, :product_id],
        Shipping::RemoveItemFromShipmentPickingList, [:order_id, :product_id]
      )
    end
  end
end