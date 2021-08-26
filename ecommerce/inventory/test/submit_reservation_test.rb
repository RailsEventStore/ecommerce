require_relative 'inventory_in_memory_test_case'

module Inventory
  class SubmitReservationTest < InventoryInMemoryTestCase

    test 'stock gets reserved on reservation submission' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
        adjust_reservation(order_id, product_id, 1)
      )
      assert_events(reservation_stream(order_id), ReservationSubmitted.new(data: { order_id: order_id, reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(inventory_entry_stream(product_id), StockReserved.new(data: { product_id: product_id, quantity: 1 })) do
          act(submit_reservation(order_id))
        end
      end
    end

    test 'submitted reservation cannot be submit again' do
      order_id = SecureRandom.uuid

      arrange(
        submit_reservation(order_id)
      )
      assert_raises(Reservation::AlreadySubmitted) do
        act(submit_reservation(order_id))
      end
    end

    test 'reservation cannot be submit when inventory is out of stock' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
        adjust_reservation(order_id, product_id, 2),
        )
      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        act(submit_reservation(order_id))
      end
    end

    test 'reservation cannot be submit when inventory is reserved' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      another_order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
        adjust_reservation(order_id, product_id, 1),
        submit_reservation(order_id),
        adjust_reservation(another_order_id, product_id, 1)
      )
      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        act(submit_reservation(another_order_id))
      end
    end

    test 'reservation can be submit when inventory stock level is undefined' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        adjust_reservation(order_id, product_id, 1),
        )
      assert_nothing_raised do
        assert_events(inventory_entry_stream(product_id)) do
          act(submit_reservation(order_id))
        end
      end
    end
  end
end