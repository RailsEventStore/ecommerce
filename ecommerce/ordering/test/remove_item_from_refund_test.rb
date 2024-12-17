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

    def test_can_remove_only_added_items
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        CreateDraftRefund.new(
          refund_id: aggregate_id,
          order_id: order_id
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
