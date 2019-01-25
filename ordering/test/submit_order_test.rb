require_relative 'test_helper'

module Ordering
  class SubmitOrderTest < ActiveSupport::TestCase
    include TestCase

    cover 'Ordering::OnSubmitOrder*'

    test 'order is submitted' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      order_number = "2019/01/60"
      arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])

      published = act(stream, SubmitOrder.new(order_id: aggregate_id, customer_id: customer.id))

      assert_changes(published, [OrderSubmitted.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer.id})])
    end

    test 'could not create order where customer is not given' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      assert_raises(Command::Invalid) do
        act(stream, SubmitOrder.new(order_id: aggregate_id, customer_id: nil))
      end
    end

    test 'already created order could not be created again' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      another_customer = Customer.create(name: 'another')
      order_number = "2019/01/60"

      arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer.id})])

      assert_raises(Order::AlreadySubmitted) do
        act(stream, SubmitOrder.new(order_id: aggregate_id, customer_id: another_customer.id))
      end
    end

    test 'expired order could not be created' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        OrderExpired.new(data: {order_id: aggregate_id})])

      assert_raises(Order::OrderHasExpired) do
        act(stream, SubmitOrder.new(order_id: aggregate_id, customer_id: customer.id))
      end
    end
  end
end