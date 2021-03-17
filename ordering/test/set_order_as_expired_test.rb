require_relative 'test_helper'

module Ordering
  class SetOrderAsExpiredTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Ordering::OnSetOrderAsExpired*'

    test 'draft order will expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product.id)
      )

      assert_events(stream, OrderExpired.new(data: { order_id: aggregate_id })) do
        act(SetOrderAsExpired.new(order_id: aggregate_id))
      end
    end

    test 'submitted order will expire' do
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
        OrderExpired.new(data: { order_id: aggregate_id })
      ) { act(SetOrderAsExpired.new(order_id: aggregate_id)) }
    end

    test 'paid order cannot expire' do
      aggregate_id = SecureRandom.uuid
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

      assert_raises(Order::AlreadyPaid) do
        act(SetOrderAsExpired.new(order_id: aggregate_id))
      end
    end
  end
end
