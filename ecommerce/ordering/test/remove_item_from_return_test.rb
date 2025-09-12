require_relative "test_helper"

module Ordering
  class RemoveItemFromReturnTest < Test
    cover "Ordering::OnRemoveItemFromReturn*"

    def test_removing_items_from_return
      order_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      product_3_id = SecureRandom.uuid
      stream = "Ordering::Return$#{aggregate_id}"

      arrange(
        Pricing::SetPrice.new(product_id: product_1_id, price: 11),
        Pricing::SetPrice.new(product_id: product_2_id, price: 22),
        Pricing::SetPrice.new(product_id: product_3_id, price: 33),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_1_id, price: 11),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_2_id, price: 22),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_2_id, price: 22),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_3_id, price: 33),
        Pricing::AcceptOffer.new(order_id: order_id),
        Fulfillment::RegisterOrder.new(order_id: order_id),
        CreateDraftReturn.new(
          return_id: aggregate_id,
          order_id: order_id
        ),
        AddItemToReturn.new(
          return_id: aggregate_id,
          order_id: order_id,
          product_id: product_1_id
        )
      )

      expected_events = [
        ItemRemovedFromReturn.new(
          data: {
            return_id: aggregate_id,
            order_id: order_id,
            product_id: product_1_id
          }
        )
      ]

      assert_events(stream, *expected_events) do
        act(
          RemoveItemFromReturn.new(
            return_id: aggregate_id,
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
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 11),
        Pricing::AcceptOffer.new(order_id: order_id),
        Fulfillment::RegisterOrder.new(order_id: order_id),
        CreateDraftReturn.new(
          return_id: aggregate_id,
          order_id: order_id
        ),
        AddItemToReturn.new(
          return_id: aggregate_id,
          order_id: order_id,
          product_id: product_id
        ),
        RemoveItemFromReturn.new(
          return_id: aggregate_id,
          order_id: order_id,
          product_id: product_id
        )
      )

      assert_raises(Return::ReturnHaveNotBeenRequestedForThisProductError) do
        act(
          RemoveItemFromReturn.new(
            return_id: aggregate_id,
            order_id: order_id,
            product_id: product_id
          )
        )
      end
    end
  end
end
