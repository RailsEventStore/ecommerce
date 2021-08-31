require_relative 'test_helper'

module Ordering
  class SubmitOrderTest < Ecommerce::InMemoryTestCase
    include TestPlumbing.with(
      event_store: ->{ Rails.configuration.event_store },
      command_bus: ->{ Rails.configuration.command_bus }
    )

    cover 'Ordering::OnSubmitOrder*'

    test 'order is submitted' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer_id = SecureRandom.uuid
      command_bus.call(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      order_number = FakeNumberGenerator::FAKE_NUMBER
      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id)
      )

      assert_events(
        stream,
        OrderSubmitted.new(
          data: {
            order_id: aggregate_id,
            order_number: order_number,
            customer_id: customer_id
          }
        )
      ) do
        act(SubmitOrder.new(order_id: aggregate_id, customer_id: customer_id))
      end
    end

    test 'could not create order where customer is not given' do
      aggregate_id = SecureRandom.uuid

      assert_raises(Command::Invalid) do
        act(SubmitOrder.new(order_id: aggregate_id, customer_id: nil))
      end
    end

    test 'already created order could not be created again' do
      aggregate_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      command_bus.call(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'test'))
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      another_customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: another_customer_id, name: 'another'))
      order_number = FakeNumberGenerator::FAKE_NUMBER

      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: order_number,
          customer_id: customer_id
        )
      )

      assert_raises(Order::AlreadySubmitted) do
        act(
          SubmitOrder.new(
            order_id: aggregate_id,
            customer_id: another_customer_id
          )
        )
      end
    end

    test 'expired order could not be created' do
      aggregate_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'test'))
      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      arrange(
        Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SetOrderAsExpired.new(order_id: aggregate_id)
      )

      assert_raises(Order::OrderHasExpired) do
        act(
          SubmitOrder.new(order_id: aggregate_id, customer_id: customer_id)
        )
      end
    end
  end
end
