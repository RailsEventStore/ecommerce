require_relative "test_helper"

module Ordering
  class RejectOrderTest < Test
    cover "Ordering::OnRejectOrder*"

    def test_order_gets_rejected
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
        SubmitOrder.new(
          order_id: aggregate_id,
          customer_id: customer_id
        )
      )

      assert_events(
        stream,
        OrderRejected.new(
          data: {
            order_id: aggregate_id
          }
        )
      ) do
        act(RejectOrder.new(order_id: aggregate_id))
      end
    end

    def test_order_must_be_pre_submitted_to_get_rejected
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        )
      )

      assert_raises(Order::InvalidState) do
        act(RejectOrder.new(order_id: aggregate_id))
      end
    end
  end
end
