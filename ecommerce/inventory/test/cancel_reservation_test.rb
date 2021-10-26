require_relative "test_helper"

module Inventory
  class CancelReservationTest < Test
    def test_stock_gets_released_on_submitted_reservation_cancellation
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(supply(product_id, 1), submit_reservation(order_id, product_id => 1))
      assert_events(
        reservation_stream(order_id),
        ReservationCanceled.new(
          data: {
            order_id: order_id,
            reservation_items: [product_id: product_id, quantity: 1]
          }
        )
      ) do
        assert_events(
          inventory_entry_stream(product_id),
          StockReleased.new(data: { product_id: product_id, quantity: 1 })
        ) { act(cancel_reservation(order_id)) }
      end
    end

    def test_not_submitted_reservation_does_not_get_canceled
      order_id = SecureRandom.uuid

      arrange(cancel_reservation(order_id))
      assert_events(reservation_stream(order_id)) do
        act(cancel_reservation(order_id))
      end
    end

    def test_canceled_reservation_cannot_be_canceled_again
      order_id = SecureRandom.uuid

      arrange(submit_reservation(order_id), cancel_reservation(order_id))
      assert_raises(Reservation::AlreadyCanceled) do
        act(cancel_reservation(order_id))
      end
    end

    def test_completed_reservation_cannot_be_canceled
      order_id = SecureRandom.uuid

      arrange(submit_reservation(order_id), complete_reservation(order_id))
      assert_raises(Reservation::AlreadyCompleted) do
        act(cancel_reservation(order_id))
      end
    end
  end
end
