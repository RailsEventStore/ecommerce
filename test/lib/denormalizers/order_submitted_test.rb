require 'test_helper'

module Denormalizers
  class OrderSubmittedTest < ActiveSupport::TestCase
    test 'create when not exists' do
      event_store = Rails.application.config.event_store

      customer = Customer.create(name: 'dummy')
      product = Product.create(name: 'something')
      order_id = SecureRandom.uuid
      order_number = "123/08/2015"

      event_store.publish_event(Events::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish_event(Events::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer.id}))

      assert_equal(::Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, 'Submitted')
      assert_equal(order.number, order_number)
      assert_equal(order.customer, 'dummy')
    end

    test 'skip when duplicated' do
      event_store = Rails.application.config.event_store

      customer = Customer.create(name: 'dummy')
      product = Product.create(name: 'something')
      order_id = SecureRandom.uuid
      order_number = "123/08/2015"
      event_store.publish_event(Events::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish_event(Events::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer.id}))

      event_store.publish_event(Events::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer.id}))

      assert_equal(::Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, 'Submitted')
      assert_equal(order.number, order_number)
      assert_equal(order.customer, 'dummy')
    end
  end
end
