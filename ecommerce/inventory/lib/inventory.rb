require "infra"
require_relative "inventory/commands/submit_reservation"
require_relative "inventory/commands/cancel_reservation"
require_relative "inventory/commands/complete_reservation"
require_relative "inventory/commands/supply"
require_relative "inventory/events/reservation_canceled"
require_relative "inventory/events/reservation_completed"
require_relative "inventory/events/reservation_submitted"
require_relative "inventory/events/stock_level_changed"
require_relative "inventory/events/stock_released"
require_relative "inventory/events/stock_reserved"
require_relative "inventory/reservation_service"
require_relative "inventory/inventory_entry_service"
require_relative "inventory/inventory_entry"
require_relative "inventory/reservation"

module Inventory
  class Configuration
    def call(event_store, command_bus)
      reservation = ReservationService.new(event_store)
      inventory = InventoryEntryService.new(event_store)

      command_bus.register(
        SubmitReservation,
        reservation.public_method(:submit_reservation)
      )
      command_bus.register(
        CancelReservation,
        reservation.public_method(:cancel_reservation)
      )
      command_bus.register(
        CompleteReservation,
        reservation.public_method(:complete_reservation)
      )
      command_bus.register(
        Supply,
        inventory.public_method(:supply)
      )
    end
  end
end
