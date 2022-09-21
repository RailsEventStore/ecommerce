module Processes
  class SyncInventoryFromOrdering
    def initialize(cqrs)
      cqrs.process(
        Ordering::OrderSubmitted,     [:order_id, :order_lines],
        Inventory::SubmitReservation, [:order_id, :reservation_items]
      )
      cqrs.process(
        Ordering::OrderConfirmed,       [:order_id],
        Inventory::CompleteReservation, [:order_id]
      )
      cqrs.process(
        Ordering::OrderExpired,       [:order_id],
        Inventory::CancelReservation, [:order_id]
      )
      cqrs.process(
        Ordering::OrderCancelled,       [:order_id],
        Inventory::CancelReservation,   [:order_id]
      )
    end
  end
end