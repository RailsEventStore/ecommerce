require_relative "test_helper"

module Inventory
  class SubmitReservationTest < Test
    def test_stock_gets_reserved_on_reservation_submission
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
      )
      assert_events(
        reservation_stream(order_id),
        ReservationSubmitted.new(
          data: {
            order_id: order_id,
            reservation_items: { product_id => 1}
          }
        )
      ) do
        assert_events(
          inventory_entry_stream(product_id),
          StockReserved.new(data: { product_id: product_id, quantity: 1 })
        ) do
          act(submit_reservation(order_id, product_id => 1))
        end
      end
    end

    def test_submitted_reservation_cannot_be_submit_again
      order_id = SecureRandom.uuid

      arrange(submit_reservation(order_id))
      assert_raises(Reservation::AlreadySubmitted) do
        act(submit_reservation(order_id))
      end
    end

    def test_reservation_cannot_be_submit_when_inventory_is_out_of_stock
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
      )
      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        act(submit_reservation(order_id, product_id => 2))
      end
    end

    def test_reservation_cannot_be_submit_when_inventory_is_reserved
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      another_order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
        submit_reservation(order_id, product_id => 1),
      )
      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        act(submit_reservation(another_order_id, product_id => 1))
      end
    end

    def test_reservation_can_be_submit_when_inventory_stock_level_is_undefined
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      assert_events(inventory_entry_stream(product_id)) do
        act(submit_reservation(order_id, product_id => 1))
      end
    end
  end
end
