require_relative 'test_helper'

module Ordering
  class AddItemToBasketTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Ordering::OnAddItemToBasket*'

    test 'item is added to draft order' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = ProductCatalog::Product.create(name: 'test')

      assert_events(
        stream,
        ItemAddedToBasket.new(
          data: {
            order_id: aggregate_id,
            product_id: product.id
          }
        )
      ) do
        act(AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end

    test 'no add allowed to submitted order' do
      aggregate_id = SecureRandom.uuid
      customer = Customer.create(name: 'test')
      product = ProductCatalog::Product.create(name: 'test')
      order_number = FakeNumberGenerator::FAKE_NUMBER
      arrange(
        AddItemToBasket.new(order_id: aggregate_id, product_id: product.id),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: order_number,
          customer_id: customer.id
        )
      )

      assert_raises(Order::AlreadySubmitted) do
        act(AddItemToBasket.new(order_id: aggregate_id, product_id: product.id))
      end
    end
  end
end
