require_relative 'test_helper'

module Ordering
  class CancelOrderTest < ActiveSupport::TestCase
    include TestCase

    cover 'Ordering::OnCancelOrder*'

    test 'draft order can be cancelled' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})], expected_version: -1)

      published = act(stream, CancelOrder.new(order_id: aggregate_id))

      assert_changes(published, [OrderCancelled.new(data: {order_id: aggregate_id})])
    end

    test 'submitted order can be cancelled' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      customer = Customer.create(name: 'dummy')
      arrange(
        stream,
        [ ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
          OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer.id}),
        ],
        expected_version: -1
      )

      published = act(stream, CancelOrder.new(order_id: aggregate_id))

      assert_changes(published, [OrderCancelled.new(data: {order_id: aggregate_id})])
    end

    test 'paid order can be cancelled' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      customer = Customer.create(name: 'dummy')
      arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer.id}),
        OrderPaid.new(data: {order_id: aggregate_id, transaction_id: SecureRandom.hex(16)}),
      ])

      published = act(stream, CancelOrder.new(order_id: aggregate_id))

      assert_changes(published, [OrderCancelled.new(data: {order_id: aggregate_id})])
    end
  end
end
