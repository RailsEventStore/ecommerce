require_relative 'test_helper'

module Ordering
  class RemoveItemFromBasketTest < ActiveSupport::TestCase
    include TestCase

    cover 'Ordering::OnRemoveItemFromBasket*'

    test 'item is removed from draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])
      published = act(stream, RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product.id))
      assert_changes(published, [ItemRemovedFromBasket.new(data: {order_id: aggregate_id, product_id: product.id})])
    end

    test 'no remove allowed to created order' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      order_number = "2019/01/60"
      arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer.id})])

      assert_raises(Order::AlreadySubmitted) do
        act(stream, RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end
  end
end