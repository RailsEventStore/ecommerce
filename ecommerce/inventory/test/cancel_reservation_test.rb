require_relative 'inventory_in_memory_test_case'

module Inventory
  class CancelReservationTest < InventoryInMemoryTestCase

    test 'stock gets released on submitted reservation cancellation' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
        adjust_reservation(order_id, product_id, 1),
        submit_reservation(order_id),
      )
      assert_events(reservation_stream(order_id), ReservationCanceled.new(data: { order_id: order_id, reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(inventory_entry_stream(product_id), StockReleased.new(data: { product_id: product_id, quantity: 1 })) do
          act(cancel_reservation(order_id))
        end
      end
    end

    test 'stock does not change on not completed reservation cancellation' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
        adjust_reservation(order_id, product_id, 1)
      )
      assert_events(reservation_stream(order_id), ReservationCanceled.new(data: { order_id: order_id, reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(inventory_entry_stream(product_id)) do
          act(cancel_reservation(order_id))
        end
      end
    end

    test 'canceled reservation cannot be canceled again' do
      order_id = SecureRandom.uuid

      arrange(
        cancel_reservation(order_id)
      )
      assert_raises(Reservation::AlreadyCanceled) do
        act(cancel_reservation(order_id))
      end
    end

    test 'completed reservation cannot be canceled' do
      order_id = SecureRandom.uuid

      arrange(
        submit_reservation(order_id),
        complete_reservation(order_id)
      )
      assert_raises(Reservation::AlreadyCompleted) do
        act(cancel_reservation(order_id))
      end
    end
  end
end

