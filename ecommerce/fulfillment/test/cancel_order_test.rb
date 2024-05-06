require_relative "test_helper"

module Fulfillment
  class CancelOrderTest < Test
    cover "Fulfillment::OnCancelOrder*"

    def test_not_registered_order_cant_be_cancelled
      aggregate_id = SecureRandom.uuid

      assert_raises(Order::InvalidState) do
        act(CancelOrder.new(order_id: aggregate_id))
      end
    end

    def test_registered_order_can_be_cancelled
      aggregate_id = SecureRandom.uuid
      stream = "Fulfillment::Order$#{aggregate_id}"
      arrange(
        RegisterOrder.new(order_id: aggregate_id)
      )

      assert_events(
        stream,
        OrderCancelled.new(data: { order_id: aggregate_id })
      ) { act(CancelOrder.new(order_id: aggregate_id)) }
    end

    def test_confirmed_order_can_not_be_cancelled
      aggregate_id = SecureRandom.uuid

      arrange(
        RegisterOrder.new(order_id: aggregate_id),
        ConfirmOrder.new(order_id: aggregate_id)
      )

      assert_raises(Order::InvalidState) do
        act(CancelOrder.new(order_id: aggregate_id))
      end
    end
  end
end
