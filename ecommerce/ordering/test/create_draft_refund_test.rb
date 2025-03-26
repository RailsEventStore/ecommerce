require_relative "test_helper"

module Ordering
  class CreateDraftRefundTest < Test
    cover "Ordering::OnCreateDraftRefund*"

    def test_draft_refund_created
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Ordering::Refund$#{aggregate_id}"

      arrange(
        Pricing::SetPrice.new(product_id: product_id, price: 11),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id),
        Pricing::AcceptOffer.new(order_id: order_id),
        Fulfillment::RegisterOrder.new(order_id: order_id),
      )

      expected_events = [
        DraftRefundCreated.new(
          data: {
            refund_id: aggregate_id,
            order_id: order_id,
            refundable_products: [{ product_id:, quantity: 2 }]
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          CreateDraftRefund.new(
            refund_id: aggregate_id,
            order_id: order_id
          )
        )
      end
    end
  end
end
