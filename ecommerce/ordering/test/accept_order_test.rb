require_relative "test_helper"

module Ordering
  class AcceptOrderTest < Test
    cover "Ordering::OnAcceptOrder*"

    def test_order_gets_accepted
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_number = FakeNumberGenerator::FAKE_NUMBER
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
        OrderSubmitted.new(
          data: {
            order_id: aggregate_id,
            order_number: order_number,
            order_lines: { product_id => 1 }
          }
        )
      ) do
        act(AcceptOrder.new(order_id: aggregate_id))
      end
    end

    def test_order_must_be_pre_submitted_to_get_accepted
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        )
      )

      assert_raises(Order::InvalidState) do
        act(AcceptOrder.new(order_id: aggregate_id))
      end
    end
  end
end
