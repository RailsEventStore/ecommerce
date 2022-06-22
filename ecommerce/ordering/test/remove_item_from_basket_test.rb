require_relative "test_helper"

module Ordering
  class RemoveItemFromBasketTest < Test
    cover "Ordering::OnRemoveItemFromBasket*"

    def test_item_is_removed_from_draft_order
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"

      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        )
      )
      expected_events = [
        ItemRemovedFromBasket.new(
          data: {
            order_id: aggregate_id,
            product_id: product_id
          }
        )
      ]
      assert_events(stream, *expected_events) do
        act(
          RemoveItemFromBasket.new(
            order_id: aggregate_id,
            product_id: product_id
          )
        )
      end
    end

    def test_no_remove_allowed_to_created_order
      aggregate_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_number = FakeNumberGenerator::FAKE_NUMBER

      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SubmitOrder.new(order_id: aggregate_id, order_number: order_number, customer_id: customer_id)
      )

      assert_raises(Order::AlreadySubmitted) do
        act(RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product_id))
      end
    end

    def test_no_remove_allowed_if_item_quantity_eq_zero
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      assert_raises(Order::CannotRemoveZeroQuantityItem) do
        act(RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product_id))
      end
    end
  end
end
