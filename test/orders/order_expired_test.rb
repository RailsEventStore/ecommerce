require 'test_helper'

module Orders
  class OrderExpiredTest < ActiveJob::TestCase

    cover 'Orders'

    test 'expire created order' do
      event_store = Rails.configuration.event_store

      customer = Customer.create(name: 'dummy')
      product = ProductCatalog::Product.create(name: 'something')
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      event_store.publish(Pricing::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product.id}))
      event_store.publish(Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer.id}))

      event_store.publish(Ordering::OrderExpired.new(data: {order_id: order_id}))

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, 'Expired')
    end
  end
end
