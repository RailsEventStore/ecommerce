require_relative "test_helper"

module Ordering
  class CreateDraftReturnTest < Test
    cover "Ordering::OnCreateDraftReturn*"

    def test_draft_return_created
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Ordering::Return$#{aggregate_id}"

      arrange(
        Pricing::SetPrice.new(product_id: product_id, price: 11),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 11),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 11),
        Pricing::AcceptOffer.new(order_id: order_id),
        Fulfillment::RegisterOrder.new(order_id: order_id),
      )

      expected_events = [
        DraftReturnCreated.new(
          data: {
            return_id: aggregate_id,
            order_id: order_id,
            returnable_products: [{ product_id:, quantity: 2 }]
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          CreateDraftReturn.new(
            return_id: aggregate_id,
            order_id: order_id
          )
        )
      end
    end
  end
end
