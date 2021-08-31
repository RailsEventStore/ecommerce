require_relative 'test_helper'

module Ordering
  class SetOrderAsExpiredTest < Ecommerce::InMemoryTestCase
    include TestPlumbing.with(
      event_store: ->{ Rails.configuration.event_store },
      command_bus: ->{ Rails.configuration.command_bus }
    )

    cover 'Ordering::OnSetOrderAsExpired*'

    def test_draft_order_will_expire
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

    def test_submitted_order_will_expire
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

    def test_paid_order_cannot_expire
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
