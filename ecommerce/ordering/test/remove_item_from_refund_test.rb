require_relative "test_helper"

module Ordering
  class RemoveItemFromRefundTest < Test
    cover "Ordering::OnRemoveItemFromRefund*"

    def test_removing_items_from_refund
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      product_3_id = SecureRandom.uuid
      stream = "Ordering::Refund$#{aggregate_id}"

      arrange(
        Pricing::SetPrice.new(product_id: product_1_id, price: 11),
        Pricing::SetPrice.new(product_id: product_2_id, price: 22),
        Pricing::SetPrice.new(product_id: product_3_id, price: 33),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_1_id),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_2_id),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_2_id),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_3_id),
        Pricing::AcceptOffer.new(order_id: order_id),
        Fulfillment::RegisterOrder.new(order_id: order_id),
        CreateDraftRefund.new(
          refund_id: aggregate_id,
          order_id: order_id
        ),
        AddItemToRefund.new(
          refund_id: aggregate_id,
          order_id: order_id,
          product_id: product_1_id
        )
      )

      expected_events = [
        ItemRemovedFromRefund.new(
          data: {
            refund_id: aggregate_id,
            order_id: order_id,
            product_id: product_1_id
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          RemoveItemFromRefund.new(
            refund_id: aggregate_id,
            order_id: order_id,
            product_id: product_1_id
          )
        )
      end
    end

    def test_cant_remove_item_with_0_quantity
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        Pricing::SetPrice.new(product_id: product_id, price: 11),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id),
        Pricing::AcceptOffer.new(order_id: order_id),
        Fulfillment::RegisterOrder.new(order_id: order_id),
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

      assert_raises(Refund::RefundHaveNotBeenRequestedForThisProductError) do
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
