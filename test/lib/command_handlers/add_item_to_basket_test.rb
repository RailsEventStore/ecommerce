require 'test_helper'

module CommandHandlers
  class AddItemToBasketTest < ActiveSupport::TestCase
    include CommandHandlers::TestCase

    test 'item is added to draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Domain::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      published = act(stream, Command::AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
      assert_changes(published, [Events::ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])
    end

    test 'no add allowed to submitted order' do
      aggregate_id = SecureRandom.uuid
      stream = "Domain::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      order_number = "123/08/2015"
      arrange(stream, [
        Events::ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        Events::OrderSubmitted.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer.id})])

      assert_raises(Domain::Order::AlreadySubmitted) do
        act(stream, Command::AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end
  end
end
