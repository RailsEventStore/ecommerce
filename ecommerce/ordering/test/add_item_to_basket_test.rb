require_relative "test_helper"

module Ordering
  class AddItemToBasketTest < Test
    cover "Pricing::OnAddItemToBasket*"

    def test_item_is_added_to_draft_order
      aggregate_id = SecureRandom.uuid
      stream = "Pricing::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      expected_events = [
        Pricing::ItemAddedToBasket.new(
          data: {
            order_id: aggregate_id,
            product_id: product_id
          }
        ),
        Pricing::OrderTotalValueCalculated.new(data: {order_id: aggregate_id, discounted_amount: 39, total_amount: 39})
      ]
      assert_events(
        stream,
        *expected_events
      ) do
        act(Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      end
    end
  end
end
