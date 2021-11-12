require "infra"
require_relative "inventory/commands/submit_reservation"
require_relative "inventory/commands/cancel_reservation"
require_relative "inventory/commands/complete_reservation"
require_relative "inventory/commands/supply"
require_relative "inventory/commands/check_availability"
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
    def call(cqrs)
      reservation = ReservationService.new(cqrs.event_store)
      inventory = InventoryEntryService.new(cqrs.event_store)

      cqrs.register_command(
        SubmitReservation,
        reservation.public_method(:submit_reservation),
        ReservationSubmitted
      )
      cqrs.register_command(
        CancelReservation,
        reservation.public_method(:cancel_reservation),
        ReservationCanceled
      )
      cqrs.register_command(
        CompleteReservation,
        reservation.public_method(:complete_reservation),
        ReservationCompleted
      )
      cqrs.register_command(
        Supply,
        inventory.public_method(:supply),
        StockLevelChanged
      )
      cqrs.register_command(
        CheckAvailability,
        inventory.public_method(:check_availability),
        nil
      )
    end
  end
end
