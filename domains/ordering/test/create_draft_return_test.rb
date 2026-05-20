require_relative "test_helper"

module Ordering
  class CreateDraftReturnTest < Test
    cover "Ordering::OnCreateDraftReturn*"

    def test_draft_return_created
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Ordering::Return$#{aggregate_id}"

      returnable_products = [{ product_id: product_id, quantity: 2 }]

      expected_events = [
        DraftReturnCreated.new(
          data: {
            return_id: aggregate_id,
            order_id: order_id,
            returnable_products: returnable_products
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          CreateDraftReturn.new(
            return_id: aggregate_id,
            order_id: order_id,
            returnable_products: returnable_products
          )
        )
      end
    end
  end
end
