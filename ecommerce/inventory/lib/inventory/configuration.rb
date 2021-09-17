module Inventory
  class Configuration
    def initialize(cqrs, event_store)
      @cqrs = cqrs
      @event_store = event_store
    end

    def call
      @cqrs.register(AdjustReservation, reservation = ReservationService.new(@event_store))
      @cqrs.register(SubmitReservation, reservation)
      @cqrs.register(CancelReservation, reservation)
      @cqrs.register(CompleteReservation, reservation)
      @cqrs.register(Supply, InventoryEntryService.new(@event_store))
    end
  end
end