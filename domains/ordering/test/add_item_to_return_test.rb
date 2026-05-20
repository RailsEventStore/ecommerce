require_relative "test_helper"

module Ordering
  class AddItemToReturnTest < Test
    cover "Ordering::OnAddItemToReturn*"

    def test_add_item_to_return
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      product_3_id = SecureRandom.uuid
      stream = "Ordering::Return$#{aggregate_id}"

      returnable_products = [
        { product_id: product_1_id, quantity: 1 },
        { product_id: product_2_id, quantity: 2 },
        { product_id: product_3_id, quantity: 1 },
      ]

      arrange(
        CreateDraftReturn.new(return_id: aggregate_id, order_id: order_id, returnable_products: returnable_products),
        AddItemToReturn.new(return_id: aggregate_id, order_id: order_id, product_id: product_2_id)
      )

      expected_events = [
        ItemAddedToReturn.new(
          data: {
            return_id: aggregate_id,
            order_id: order_id,
            product_id: product_2_id
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          AddItemToReturn.new(
            return_id: aggregate_id,
            order_id: order_id,
            product_id: product_2_id
          )
        )
      end
    end

    def test_add_item_raises_exceeds_order_quantity_error
      aggregate_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        CreateDraftReturn.new(return_id: aggregate_id, order_id: order_id, returnable_products: [{ product_id: product_id, quantity: 1 }]),
        AddItemToReturn.new(return_id: aggregate_id, order_id: order_id, product_id: product_id)
      )

      assert_raises(Ordering::Return::ExceedsOrderQuantityError) do
        act(AddItemToReturn.new(return_id: aggregate_id, order_id: order_id, product_id: product_id))
      end
    end
  end
end
