require 'test_helper'

module Orders
  class ItemRemovedFromBasketTest < ActiveJob::TestCase
    test 'remove item when quantity > 1' do
      event_store = Rails.configuration.event_store

      product = Product.create(name: 'something')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "2019/01/60"
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish(Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer.id}))

      event_store.publish(Ordering::ItemRemovedFromBasket.new(data: {order_id: order_id, product_id: product.id}))

      assert_equal(OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product.id)
      assert_equal(order_line.product_name, 'something')
      assert_equal(order_line.quantity , 1)
    end

    test 'remove item when quantity = 1' do
      event_store = Rails.configuration.event_store

      product = Product.create(name: 'something')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "2019/01/60"
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish(Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer.id}))

      event_store.publish(Ordering::ItemRemovedFromBasket.new(data: {order_id: order_id, product_id: product.id}))

      assert_equal(OrderLine.count, 0)
    end

    test 'remove item when there is another item' do
      event_store = Rails.configuration.event_store

      product = Product.create(name: 'something')
      another_product = Product.create(name: '2nd one')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "2019/01/60"
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish(Ordering::ItemAddedToBasket.new(data: {order_id: order_id, product_id: another_product.id}))
      event_store.publish(Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer.id}))

      event_store.publish(Ordering::ItemRemovedFromBasket.new(data: {order_id: order_id, product_id: another_product.id}))

      assert_equal(OrderLine.count, 1)
      order_lines = OrderLine.where(order_uid: order_id)
      assert_equal(order_lines[0].product_id, product.id)
      assert_equal(order_lines[0].product_name, 'something')
      assert_equal(order_lines[0].quantity , 2)
    end
  end
end
