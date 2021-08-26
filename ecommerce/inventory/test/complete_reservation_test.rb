require_relative 'inventory_in_memory_test_case'

module Inventory
  class CompleteReservationTest < InventoryInMemoryTestCase

    test 'stock level changes on reservation completion' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1),
        adjust_reservation(order_id, product_id, 1),
        submit_reservation(order_id)
      )
      assert_events(reservation_stream(order_id),
                    ReservationCompleted.new(data: { order_id: order_id, reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(inventory_entry_stream(product_id),
                      StockReleased.new(data: { product_id: product_id, quantity: 1 }),
                      StockLevelChanged.new(data: { product_id: product_id, quantity: -1, stock_level: 0 })) do
          act(complete_reservation(order_id))
        end
      end
    end

    test 'completed reservation cannot be complete again' do
      order_id = SecureRandom.uuid

      arrange(
        submit_reservation(order_id),
        complete_reservation(order_id)
      )
      assert_raises(Reservation::AlreadyCompleted) do
        act(complete_reservation(order_id))
      end
    end

    test 'not submitted reservation cannot be complete' do
      order_id = SecureRandom.uuid

      assert_raises(Reservation::NotSubmitted) do
        act(complete_reservation(order_id))
      end
    end

    test 'canceled reservation cannot be complete' do
      order_id = SecureRandom.uuid

      arrange(
        cancel_reservation(order_id)
      )
      assert_raises(Reservation::AlreadyCanceled) do
        act(complete_reservation(order_id))
      end
    end
  end
end

