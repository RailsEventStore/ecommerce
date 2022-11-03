module Processes
  class SyncInventoryFromOrdering
    def initialize(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::OrderSubmitted, [:order_id, :order_lines],
                          Inventory::SubmitReservation, [:order_id, :reservation_items])
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::OrderConfirmed, [:order_id],
                          Inventory::CompleteReservation, [:order_id])
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::OrderExpired, [:order_id],
                          Inventory::CancelReservation, [:order_id])
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::OrderCancelled, [:order_id],
                          Inventory::CancelReservation, [:order_id])
    end
  end
end