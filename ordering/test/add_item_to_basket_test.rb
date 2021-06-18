require_relative 'test_helper'

module Ordering
  class AddItemToBasketTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Pricing::OnAddItemToBasket*'

    test 'item is added to draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Pricing::Order$#{aggregate_id}"
      product = ProductCatalog::Product.create(name: 'test')

      assert_events(
        stream,
        Pricing::ItemAddedToBasket.new(
          data: {
            order_id: aggregate_id,
            product_id: product.id
          }
        )
      ) do
        act(Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end
  end
end
