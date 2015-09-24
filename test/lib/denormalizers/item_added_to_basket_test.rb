require 'test_helper'

module Denormalizers
  class ItemAddedToBasketTest < ActiveSupport::TestCase
    include EventStoreSetup

    test 'add new item' do
      product = Product.create(name: 'something')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "123/08/2015"
      event_store.publish_event(Events::OrderCreated.create(order_id, order_number, customer.id))

      event_store.publish_event(Events::ItemAddedToBasket.create(order_id, product.id))

      assert_equal(::OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product.id)
      assert_equal(order_line.product_name, 'something')
      assert_equal(order_line.quantity , 1)
    end

    test 'add the same item 2nd time' do
      product = Product.create(name: 'something')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "123/08/2015"
      event_store.publish_event(Events::OrderCreated.create(order_id, order_number, customer.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(order_id, product.id))

      event_store.publish_event(Events::ItemAddedToBasket.create(order_id, product.id))

      assert_equal(::OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product.id)
      assert_equal(order_line.product_name, 'something')
      assert_equal(order_line.quantity , 2)
    end

    test 'add another item' do
      product = Product.create(name: 'something')
      another_product = Product.create(name: '2nd one')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "123/08/2015"
      event_store.publish_event(Events::OrderCreated.create(order_id, order_number, customer.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(order_id, product.id))

      event_store.publish_event(Events::ItemAddedToBasket.create(order_id, another_product.id))

      assert_equal(::OrderLine.count, 2)
      order_lines = OrderLine.where(order_uid: order_id)
      assert_equal(order_lines[0].product_id, product.id)
      assert_equal(order_lines[0].product_name, 'something')
      assert_equal(order_lines[0].quantity , 1)

      assert_equal(order_lines[1].product_id, another_product.id)
      assert_equal(order_lines[1].product_name, '2nd one')
      assert_equal(order_lines[1].quantity , 1)
    end
  end
end
