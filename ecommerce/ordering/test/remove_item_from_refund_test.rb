require_relative "test_helper"

module Ordering
  class RemoveItemFromRefundTest < Test
    cover "Ordering::OnRemoveItemFromRefund*"

    def test_removing_items_from_refund
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Ordering::Refund$#{aggregate_id}"

      arrange(
        AddItemToBasket.new(order_id: order_id, product_id: product_id),
        CreateDraftRefund.new(
          refund_id: aggregate_id,
          order_id: order_id
        ),
        AddItemToRefund.new(
          refund_id: aggregate_id,
          order_id: order_id,
          product_id: product_id
        )
      )

      expected_events = [
        ItemRemovedFromRefund.new(
          data: {
            refund_id: aggregate_id,
            order_id: order_id,
            product_id: product_id
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          RemoveItemFromRefund.new(
            refund_id: aggregate_id,
            order_id: order_id,
            product_id: product_id
          )
        )
      end
    end

    def test_cant_remove_item_with_0_quantity
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(order_id: order_id, product_id: product_id),
        CreateDraftRefund.new(
          refund_id: aggregate_id,
          order_id: order_id
        ),
        AddItemToRefund.new(
          refund_id: aggregate_id,
          order_id: order_id,
          product_id: product_id
        ),
        RemoveItemFromRefund.new(
          refund_id: aggregate_id,
          order_id: order_id,
          product_id: product_id
        )
      )

      assert_raises(Refund::ProductNotFoundError) do
        act(
          RemoveItemFromRefund.new(
            refund_id: aggregate_id,
            order_id: order_id,
            product_id: product_id
          )
        )
      end
    end
  end
end
