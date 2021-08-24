module Inventory
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register(AdjustReservation, ReservationService.new)
      @cqrs.register(SubmitReservation, ReservationService.new)
      @cqrs.register(CancelReservation, ReservationService.new)
      @cqrs.register(CompleteReservation, ReservationService.new)
      @cqrs.register(Supply, InventoryEntryService.new)
    end
  end
end