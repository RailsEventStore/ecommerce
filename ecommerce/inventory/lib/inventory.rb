require "infra"
require_relative "inventory/commands/release"
require_relative "inventory/commands/supply"
require_relative "inventory/commands/reserve"
require_relative "inventory/commands/dispatch"
require_relative "inventory/events/stock_level_changed"
require_relative "inventory/events/stock_released"
require_relative "inventory/events/stock_reserved"
require_relative "inventory/events/availability_changed"
require_relative "inventory/inventory_entry_service"
require_relative "inventory/inventory_entry"

module Inventory
  class Configuration
    def call(event_store, command_bus)
      inventory = InventoryEntryService.new(event_store)

      command_bus.register(
        Reserve,
        inventory.method(:reserve)
      )
      command_bus.register(
        Release,
        inventory.method(:release)
      )
      command_bus.register(
        Supply,
        inventory.public_method(:supply)
      )
      command_bus.register(
        Dispatch,
        inventory.public_method(:dispatch)
      )
    end
  end
end
