require 'test_helper'

module CommandHandlers
  class CreateOrderTest < ActiveSupport::TestCase
    include CommandHandlers::TestCase

    test 'order is created' do
      aggregate_id = SecureRandom.uuid
      stream = "Domain::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      order_number = "123/08/2015"
      arrange(stream, [Events::ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])

      published = act(stream, Command::CreateOrder.new(order_id: aggregate_id, customer_id: customer.id))

      assert_changes(published, [Events::OrderCreated.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer.id})])
    end

    test 'could not create order where customer is not given' do
      aggregate_id = SecureRandom.uuid
      stream = "Domain::Order$#{aggregate_id}"
      assert_raises(Command::ValidationError) do
        act(stream, Command::CreateOrder.new(order_id: aggregate_id, customer_id: nil))
      end
    end

    test 'already created order could not be created again' do
      aggregate_id = SecureRandom.uuid
      stream = "Domain::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      another_customer = Customer.create(name: 'another')
      order_number = "123/08/2015"

      arrange(stream, [
        Events::ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        Events::OrderCreated.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer.id})])

      assert_raises(Domain::Order::AlreadyCreated) do
        act(stream, Command::CreateOrder.new(order_id: aggregate_id, customer_id: another_customer.id))
      end
    end

    test 'expired order could not be created' do
      aggregate_id = SecureRandom.uuid
      stream = "Domain::Order$#{aggregate_id}"
      customer = Customer.create(name: 'test')
      product = Product.create(name: 'test')
      arrange(stream, [
        Events::ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        Events::OrderExpired.new(data: {order_id: aggregate_id})])

      assert_raises(Domain::Order::OrderExpired) do
        act(stream, Command::CreateOrder.new(order_id: aggregate_id, customer_id: customer.id))
      end
    end
  end
end
