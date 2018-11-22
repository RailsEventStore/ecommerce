require 'test_helper'

class AddItemToBasketTest < ActiveSupport::TestCase
  include TestCase

  test 'item is added to draft order' do
    aggregate_id = SecureRandom.uuid
    stream = "Order$#{aggregate_id}"
    product = Product.create(name: 'test')
    published = act(stream, AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
    assert_changes(published, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])
  end

  test 'no add allowed to submitted order' do
    aggregate_id = SecureRandom.uuid
    stream = "Order$#{aggregate_id}"
    customer = Customer.create(name: 'test')
    product = Product.create(name: 'test')
    order_number = "123/08/2015"
    arrange(stream, [
      ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
      OrderSubmitted.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer.id})])

    assert_raises(Order::AlreadySubmitted) do
      act(stream, AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
    end
  end
end
