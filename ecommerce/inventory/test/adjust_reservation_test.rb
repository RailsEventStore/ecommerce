require_relative 'inventory_in_memory_test_case'

module Inventory
  class AdjustReservationTest < InventoryInMemoryTestCase

    test 'reservation can be adjusted' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      assert_events(reservation_stream(order_id), ReservationAdjusted.new(data: { order_id: order_id, product_id: product_id, quantity: 1 })) do
        act(adjust_reservation(order_id, product_id, 1))
      end
      assert_events(reservation_stream(order_id), ReservationAdjusted.new(data: { order_id: order_id, product_id: product_id, quantity: -1 })) do
        act(adjust_reservation(order_id, product_id, -1))
      end
    end

    test 'submitted reservation cannot be adjusted' do
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(
        submit_reservation(order_id)
      )
      assert_raises(Reservation::AlreadySubmitted) do
        act(adjust_reservation(order_id, product_id, 1))
      end
      arrange(
        cancel_reservation(order_id)
      )
      assert_raises(Reservation::AlreadySubmitted) do
        act(adjust_reservation(order_id, product_id, 1))
      end
    end
  end
end