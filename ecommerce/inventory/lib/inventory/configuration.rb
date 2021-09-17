module Inventory
  class Configuration
    def initialize(cqrs, event_store)
      @cqrs = cqrs
      @event_store = event_store
    end

    def call
      reservation = ReservationService.new(@event_store)
      inventory = InventoryEntryService.new(@event_store)

      @cqrs.register(AdjustReservation, reservation.method(:adjust_reservation))
      @cqrs.register(SubmitReservation, reservation.method(:submit_reservation))
      @cqrs.register(CancelReservation, reservation.method(:cancel_reservation))
      @cqrs.register(CompleteReservation, reservation.method(:complete_reservation))
      @cqrs.register(Supply, inventory.method(:supply))
    end
  end
end