require_relative "test_helper"

module Ordering
  class SetOrderAsExpiredTest < Test
    cover "Ordering::OnSetOrderAsExpired*"

    def test_draft_order_will_expire
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        )
      )

      assert_events(
        stream,
        OrderExpired.new(data: { order_id: aggregate_id })
      ) { act(SetOrderAsExpired.new(order_id: aggregate_id)) }
    end

    def test_submitted_order_will_expire
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: "2018/12/1",
          customer_id: customer_id
        )
      )

      assert_events(
        stream,
        OrderExpired.new(data: { order_id: aggregate_id })
      ) { act(SetOrderAsExpired.new(order_id: aggregate_id)) }
    end

    def test_confirmed_order_cannot_expire
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: "2018/12/1",
          customer_id: customer_id
        ),
        AcceptOrder.new(order_id: aggregate_id),
        ConfirmOrder.new(order_id: aggregate_id)
      )

      assert_raises(Order::AlreadyConfirmed) do
        act(SetOrderAsExpired.new(order_id: aggregate_id))
      end
    end
  end
end
