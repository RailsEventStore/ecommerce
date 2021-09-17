require_relative "test_helper"

module Ordering
  class SubmitOrderTest < Test
    cover "Ordering::OnSubmitOrder*"

    def test_order_is_submitted
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      customer_id = SecureRandom.uuid
      command_bus.call(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      )
      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      order_number = FakeNumberGenerator::FAKE_NUMBER
      arrange(
        Pricing::AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        )
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

    def test_could_not_create_order_where_customer_is_not_given
      aggregate_id = SecureRandom.uuid

      assert_raises(Infra::Command::Invalid) do
        act(SubmitOrder.new(order_id: aggregate_id, customer_id: nil))
      end
    end

    def test_already_created_order_could_not_be_created_again
      aggregate_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      command_bus.call(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "test")
      )
      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      another_customer_id = SecureRandom.uuid
      run_command(
        Crm::RegisterCustomer.new(
          customer_id: another_customer_id,
          name: "another"
        )
      )
      order_number = FakeNumberGenerator::FAKE_NUMBER

      arrange(
        Pricing::AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
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

    def test_expired_order_could_not_be_created
      aggregate_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      run_command(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "test")
      )
      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      arrange(
        Pricing::AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
        SetOrderAsExpired.new(order_id: aggregate_id)
      )

      assert_raises(Order::OrderHasExpired) do
        act(SubmitOrder.new(order_id: aggregate_id, customer_id: customer_id))
      end
    end
  end
end
