require_relative "test_helper"

module Ordering
  class AddItemToRefundTest < Test
    cover "Ordering::OnAddItemToRefund*"

    def test_add_item_to_refund
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Ordering::Refund$#{aggregate_id}"

      arrange(
        AddItemToBasket.new(order_id: order_id, product_id: product_id),
        CreateDraftRefund.new(
          refund_id: aggregate_id,
          order_id: order_id
        )
      )

      expected_events = [
        ItemAddedToRefund.new(
          data: {
            refund_id: aggregate_id,
            order_id: order_id,
            product_id: product_id
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          AddItemToRefund.new(
            refund_id: aggregate_id,
            order_id: order_id,
            product_id: product_id
          )
        )
      end
    end

    def test_add_item_raises_exceeds_order_quantity_error
      aggregate_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(order_id: order_id, product_id: product_id),
        CreateDraftRefund.new(refund_id: aggregate_id, order_id: order_id),
        AddItemToRefund.new(
          refund_id: aggregate_id,
          order_id: order_id,
          product_id: product_id
        )
      )

      assert_raises(Ordering::Refund::ExceedsOrderQuantityError) do
        act(AddItemToRefund.new(refund_id: aggregate_id, order_id: order_id, product_id: product_id))
      end
    end
  end
end
