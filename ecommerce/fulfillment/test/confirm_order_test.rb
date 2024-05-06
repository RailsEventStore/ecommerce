require_relative "test_helper"

module Fulfillment
  class ConfirmOrderTest < Test
    cover "Fulfillment::OnConfirmOrder*"

    def test_not_registered_order_cant_be_confirmed
      aggregate_id = SecureRandom.uuid

      assert_raises(Order::InvalidState) do
        act(ConfirmOrder.new(order_id: aggregate_id))
      end
    end

    def test_registered_order_can_be_confirmed
      aggregate_id = SecureRandom.uuid
      stream = "Fulfillment::Order$#{aggregate_id}"
      arrange(
        RegisterOrder.new(order_id: aggregate_id)
      )

      assert_events(
        stream,
        OrderConfirmed.new(data: { order_id: aggregate_id })
      ) { act(ConfirmOrder.new(order_id: aggregate_id)) }
    end

    def test_confirmed_order_can_not_be_confirmed
      aggregate_id = SecureRandom.uuid

      arrange(
        RegisterOrder.new(order_id: aggregate_id),
        CancelOrder.new(order_id: aggregate_id)
      )

      assert_raises(Order::InvalidState) do
        act(ConfirmOrder.new(order_id: aggregate_id))
      end
    end
  end
end
