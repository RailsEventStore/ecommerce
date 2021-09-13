require_relative "test_helper"

module Ordering
  class RemoveItemFromBasketTest < Ecommerce::InMemoryTestCase
    include Infra::TestPlumbing.with(
      event_store: ->{ Rails.configuration.event_store },
      command_bus: ->{ Rails.configuration.command_bus }
    )

    cover "Pricing::OnRemoveItemFromBasket*"

    def test_item_is_removed_from_draft_order
      aggregate_id = SecureRandom.uuid
      stream = "Pricing::Order$#{aggregate_id}"

      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      arrange(Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      expected_events = [
        Pricing::ItemRemovedFromBasket.new(data: {order_id: aggregate_id, product_id: product_id}),
        Pricing::OrderTotalValueCalculated.new(data: {order_id: aggregate_id, discounted_amount: 0, total_amount: 0})
      ]
      assert_events(stream, *expected_events) do
        act(Pricing::RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product_id))
      end
    end
  end
end