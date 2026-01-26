require_relative "test_helper"

module Fulfillment
  class ConfirmOrderTest < Test
    cover "Fulfillment::OnRegisterOrder*"

    def test_new_order_can_be_registered
      aggregate_id = SecureRandom.uuid
      stream = "Fulfillment::Order$#{aggregate_id}"
      order_number = FakeNumberGenerator::FAKE_NUMBER

      assert_events(
        stream,
        OrderRegistered.new(data: { order_id: aggregate_id, order_number: order_number })
      ) { act(RegisterOrder.new(order_id: aggregate_id)) }
    end

    def test_registered_order_can_not_be_registered_again
      aggregate_id = SecureRandom.uuid

      arrange(
        RegisterOrder.new(order_id: aggregate_id),
      )

      assert_raises(Order::InvalidState) do
        act(RegisterOrder.new(order_id: aggregate_id))
      end
    end
  end
end
