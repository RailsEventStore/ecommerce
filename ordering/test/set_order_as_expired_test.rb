require_relative 'test_helper'

module Ordering
  class SetOrderAsExpiredTest < ActiveSupport::TestCase
    include TestCase

    cover 'Ordering::OnSetOrderAsExpired*'

    test 'draft order will expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])

      published = act(stream, SetOrderAsExpired.new(order_id: aggregate_id))

      assert_changes(published, [OrderExpired.new(data: {order_id: aggregate_id})])
    end

    test 'submitted order will expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      customer = Customer.create(name: 'dummy')
      arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer.id}),
      ])

      published = act(stream, SetOrderAsExpired.new(order_id: aggregate_id))

      assert_changes(published, [OrderExpired.new(data: {order_id: aggregate_id})])
    end

    test 'paid order cannot expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      customer = Customer.create(name: 'dummy')
      arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer.id}),
        OrderPaid.new(data: {order_id: aggregate_id, transaction_id: SecureRandom.hex(16)}),
      ])

      assert_raises(Order::AlreadyPaid) do
        act(stream, SetOrderAsExpired.new(order_id: aggregate_id))
      end
    end
  end
end
