require_relative 'test_helper'

module Ordering
  class AddItemToBasketTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Pricing::OnAddItemToBasket*'

    test 'item is added to draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Pricing::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      assert_events(
        stream,
        Pricing::ItemAddedToBasket.new(
          data: {
            order_id: aggregate_id,
            product_id: product_id
          }
        )
      ) do
        act(Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      end
    end
  end
end
