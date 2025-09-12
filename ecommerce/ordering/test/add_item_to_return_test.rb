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
        CreateDraftReturn.new(return_id: aggregate_id, order_id: order_id),
        AddItemToReturn.new(
            return_id: aggregate_id,
            order_id: order_id,
            product_id: product_2_id
          )
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
        Pricing::SetPrice.new(product_id: product_id, price: 11),
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 11),
        Pricing::AcceptOffer.new(order_id: order_id),
        Fulfillment::RegisterOrder.new(order_id: order_id),
        CreateDraftReturn.new(return_id: aggregate_id, order_id: order_id),
        AddItemToReturn.new(
          return_id: aggregate_id,
          order_id: order_id,
          product_id: product_id
        )
      )

      assert_raises(Ordering::Return::ExceedsOrderQuantityError) do
        act(AddItemToReturn.new(return_id: aggregate_id, order_id: order_id, product_id: product_id))
      end
    end
  end
end
