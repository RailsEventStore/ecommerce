require "infra"
require_relative "shipping/commands/add_item_to_shipment_picking_list"
require_relative "shipping/events/item_added_to_shipment_picking_list"
require_relative "shipping/services/on_add_item_to_shipment_picking_list"

require_relative "shipping/commands/remove_item_from_shipment_picking_list"
require_relative "shipping/events/item_removed_from_shipment_picking_list"
require_relative "shipping/services/on_remove_item_from_shipment_picking_list"

require_relative "shipping/commands/add_shipping_address_to_shipment"
require_relative "shipping/events/shipping_address_added_to_shipment"
require_relative "shipping/services/on_add_shipping_address_to_shipment"

require_relative "shipping/commands/submit_shipment"
require_relative "shipping/events/shipment_submitted"
require_relative "shipping/services/on_submit_shipment"

require_relative "shipping/commands/authorize_shipment"
require_relative "shipping/events/shipment_authorized"
require_relative "shipping/services/on_authorize_shipment"

require_relative "shipping/shipment"
require_relative "shipping/picking_list"
require_relative "shipping/picking_list_item"

module Shipping
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(
        AddItemToShipmentPickingList,
        OnAddItemToShipmentPickingList.new(event_store)
      )
      command_bus.register(
        RemoveItemFromShipmentPickingList,
        OnRemoveItemFromShipmentPickingList.new(event_store)
      )
      command_bus.register(
        AddShippingAddressToShipment,
        OnAddShippingAddressToShipment.new(event_store)
      )
      command_bus.register(
        SubmitShipment,
        OnSubmitShipment.new(event_store)
      )
      command_bus.register(
        AuthorizeShipment,
        OnAuthorizeShipment.new(event_store)
      )
    end
  end
end
