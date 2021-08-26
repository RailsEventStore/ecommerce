require 'test_helper'

module Inventory
  class InventoryInMemoryTestCase < Ecommerce::InMemoryTestCase
    include TestPlumbing

    cover 'Inventory*'

    protected

    def inventory_entry_stream product_id
      "Inventory::InventoryEntry$#{product_id}"
    end

    def reservation_stream order_id
      "Inventory::Reservation$#{order_id}"
    end

    def supply(product_id, quantity)
      Supply.new(product_id: product_id, quantity: quantity)
    end

    def adjust_reservation(order_id, product_id, quantity)
      AdjustReservation.new(order_id: order_id, product_id: product_id, quantity: quantity)
    end

    def submit_reservation(order_id)
      SubmitReservation.new(order_id: order_id)
    end

    def cancel_reservation(order_id)
      CancelReservation.new(order_id: order_id)
    end

    def complete_reservation(order_id)
      CompleteReservation.new(order_id: order_id)
    end
  end
end