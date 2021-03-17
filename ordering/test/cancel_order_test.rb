require_relative 'test_helper'

module Ordering
  class CancelOrderTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Ordering::OnCancelOrder*'

    test "draft order can't be cancelled" do
      aggregate_id = SecureRandom.uuid
      product = Product.create(name: 'test')
      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product.id)
      )

      assert_raises(Order::NotSubmitted) do
        act(CancelOrder.new(order_id: aggregate_id))
      end
    end

    test 'submitted order can be cancelled' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      customer = Customer.create(name: 'dummy')
      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product.id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: '2018/12/1',
          customer_id: customer.id
        )
      )

      assert_events(
        stream,
        OrderCancelled.new(data: { order_id: aggregate_id })
      ) { act(CancelOrder.new(order_id: aggregate_id)) }
    end

    test 'paid order can be cancelled' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      customer = Customer.create(name: 'dummy')
      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product.id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: '2018/12/1',
          customer_id: customer.id
        ),
        MarkOrderAsPaid.new(
          order_id: aggregate_id,
          transaction_id: SecureRandom.hex(16)
        )
      )

      assert_events(
        stream,
        OrderCancelled.new(data: { order_id: aggregate_id })
      ) { act(CancelOrder.new(order_id: aggregate_id)) }
    end
  end
end
