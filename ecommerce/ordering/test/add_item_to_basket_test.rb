require_relative "test_helper"

module Ordering
  class AddItemToBasketTest < Test
    cover "Ordering::OnAddItemToBasket*"

    def test_item_is_added_to_draft_order
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      expected_events = [
        ItemAddedToBasket.new(
          data: {
            order_id: aggregate_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      ]
      assert_events(stream, *expected_events) do
        act(
          AddItemToBasket.new(
            order_id: aggregate_id,
            product_id: product_id
          )
        )
      end
    end

    def test_no_add_allowed_to_submitted_order
      aggregate_id = SecureRandom.uuid
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
      order_number = FakeNumberGenerator::FAKE_NUMBER
      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: order_number,
          customer_id: customer_id
        )
      )

      assert_raises(Order::AlreadySubmitted) do
        act(AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      end
    end
  end
end
