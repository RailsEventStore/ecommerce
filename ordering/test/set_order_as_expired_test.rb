require_relative 'test_helper'

module Ordering
  class SetOrderAsExpiredTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Ordering::OnSetOrderAsExpired*'

    test 'draft order will expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id)
      )

      assert_events(stream, OrderExpired.new(data: { order_id: aggregate_id })) do
        act(SetOrderAsExpired.new(order_id: aggregate_id))
      end
    end

    test 'submitted order will expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      customer_id = SecureRandom.uuid
      command_bus.call(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))
      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: '2018/12/1',
          customer_id: customer_id
        )
      )

      assert_events(
        stream,
        OrderExpired.new(data: { order_id: aggregate_id })
      ) { act(SetOrderAsExpired.new(order_id: aggregate_id)) }
    end

    test 'paid order cannot expire' do
      aggregate_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))
      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: '2018/12/1',
          customer_id: customer_id
        ),
        MarkOrderAsPaid.new(order_id: aggregate_id)
      )

      assert_raises(Order::AlreadyPaid) do
        act(SetOrderAsExpired.new(order_id: aggregate_id))
      end
    end
  end
end
