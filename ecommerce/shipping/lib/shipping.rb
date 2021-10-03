require "infra"
require_relative "shipping/commands/add_item_to_shipment_picking_list"
require_relative "shipping/events/item_added_to_shipment_picking_list"
require_relative "shipping/services/on_add_item_to_shipment_picking_list"

require_relative "shipping/commands/remove_item_from_shipment_picking_list"
require_relative "shipping/events/item_removed_from_shipment_picking_list"
require_relative "shipping/services/on_remove_item_from_shipment_picking_list"

require_relative "shipping/shipment"
require_relative "shipping/picking_list"
require_relative "shipping/picking_list_item"

module Shipping
  class Configuration
    def call(event_store, command_bus)
      cqrs = Infra::Cqrs.new(event_store, command_bus)

      cqrs.register(
        AddItemToShipmentPickingList,
        OnAddItemToShipmentPickingList.new(event_store)
      )
      cqrs.register(
        RemoveItemFromShipmentPickingList,
        OnRemoveItemFromShipmentPickingList.new(event_store)
      )
    end
  end
end
