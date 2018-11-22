require 'test_helper'

module Orders
  class ItemAddedToBasketTest < ActiveJob::TestCase
    test 'add new item' do
      event_store = Rails.configuration.event_store

      product = Product.create(name: 'something')
      order_id = SecureRandom.uuid

      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))

      assert_equal(OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product.id)
      assert_equal(order_line.product_name, 'something')
      assert_equal(order_line.quantity , 1)

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Draft")
      assert_nil(order.customer)
      assert_nil(order.number)
    end

    test 'add the same item 2nd time' do
      event_store = Rails.configuration.event_store

      product = Product.create(name: 'something')
      order_id = SecureRandom.uuid
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))

      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))

      assert_equal(OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product.id)
      assert_equal(order_line.product_name, 'something')
      assert_equal(order_line.quantity , 2)

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Draft")
      assert_nil(order.customer)
      assert_nil(order.number)
    end

    test 'add another item' do
      event_store = Rails.configuration.event_store

      product = Product.create(name: 'something')
      another_product = Product.create(name: '2nd one')
      order_id = SecureRandom.uuid
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))

      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: another_product.id}))

      assert_equal(OrderLine.count, 2)
      order_lines = OrderLine.where(order_uid: order_id)
      assert_equal(order_lines[0].product_id, product.id)
      assert_equal(order_lines[0].product_name, 'something')
      assert_equal(order_lines[0].quantity , 1)

      assert_equal(order_lines[1].product_id, another_product.id)
      assert_equal(order_lines[1].product_name, '2nd one')
      assert_equal(order_lines[1].quantity , 1)

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Draft")
      assert_nil(order.customer)
      assert_nil(order.number)
    end
  end
end
