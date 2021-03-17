require_relative 'test_helper'

module Ordering
  class RemoveItemFromBasketTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Ordering::OnRemoveItemFromBasket*'

    test 'item is removed from draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      arrange(AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
      assert_events(stream, ItemRemovedFromBasket.new(data: {order_id: aggregate_id, product_id: product.id})) do
        act(RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end

    test 'no remove allowed to created order' do
      aggregate_id = SecureRandom.uuid
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      order_number = FakeNumberGenerator::FAKE_NUMBER
      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product.id),
        SubmitOrder.new(order_id: aggregate_id, order_number: order_number, customer_id: customer.id)
      )

      assert_raises(Order::AlreadySubmitted) do
        act(RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end
  end
end