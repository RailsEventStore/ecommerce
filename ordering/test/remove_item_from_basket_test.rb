require_relative 'test_helper'

module Ordering
  class RemoveItemFromBasketTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Pricing::OnRemoveItemFromBasket*'

    test 'item is removed from draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Pricing::Order$#{aggregate_id}"

      product_uid = SecureRandom.uuid
      product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      arrange(Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      assert_events(stream, Pricing::ItemRemovedFromBasket.new(data: {order_id: aggregate_id, product_id: product_id})) do
        act(Pricing::RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product_id))
      end
    end
  end
end