require_relative 'test_helper'

module Ordering
  class RemoveItemFromBasketTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Pricing::OnRemoveItemFromBasket*'

    test 'item is removed from draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Pricing::Order$#{aggregate_id}"
      product = ProductCatalog::Product.create(name: 'test')
      arrange(Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
      assert_events(stream, Pricing::ItemRemovedFromBasket.new(data: {order_id: aggregate_id, product_id: product.id})) do
        act(Pricing::RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end
  end
end