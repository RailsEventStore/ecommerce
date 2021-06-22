require_relative 'test_helper'

module Ordering
  class CancelOrderTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Ordering::OnCancelOrder*'

    test "draft order can't be cancelled" do
      aggregate_id = SecureRandom.uuid

      product_uid = SecureRandom.uuid
      product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id)
      )

      assert_raises(Order::NotSubmitted) do
        act(CancelOrder.new(order_id: aggregate_id))
      end
    end

    test 'submitted order can be cancelled' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"

      product_uid = SecureRandom.uuid
      product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      customer = Customer.create(name: 'dummy')
      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
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

    test "paid order can't be cancelled" do
      aggregate_id = SecureRandom.uuid

      product_uid = SecureRandom.uuid
      product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      customer = Customer.create(name: 'dummy')
      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: '2018/12/1',
          customer_id: customer.id
        ),
        MarkOrderAsPaid.new(order_id: aggregate_id)
      )

      assert_raises(Order::NotSubmitted) do
        act(CancelOrder.new(order_id: aggregate_id))
      end
    end

    test "expired order can't be cancelled" do
      aggregate_id = SecureRandom.uuid

      product_uid = SecureRandom.uuid
      product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      customer = Customer.create(name: 'dummy')
      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: '2018/12/1',
          customer_id: customer.id
        ),
        SetOrderAsExpired.new(order_id: aggregate_id)
      )

      assert_raises(Order::OrderHasExpired) do
        act(CancelOrder.new(order_id: aggregate_id))
      end
    end
  end
end
