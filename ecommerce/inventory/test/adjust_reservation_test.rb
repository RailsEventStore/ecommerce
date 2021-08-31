require_relative 'inventory_in_memory_test_case'

module Inventory
  class AdjustReservationTest < InventoryInMemoryTestCase

    def test_reservation_can_be_adjusted
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      assert_events(reservation_stream(order_id), ReservationAdjusted.new(data: { order_id: order_id, product_id: product_id, quantity: 1 })) do
        act(adjust_reservation(order_id, product_id, 1))
      end
      assert_events(reservation_stream(order_id), ReservationAdjusted.new(data: { order_id: order_id, product_id: product_id, quantity: -1 })) do
        act(adjust_reservation(order_id, product_id, -1))
      end
    end

    def test_submitted_reservation_cannot_be_adjusted
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