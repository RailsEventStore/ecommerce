require "test_helper"

module Orders
  class OrderCancelledTest < InMemoryTestCase
    cover "Orders*"

    def test_cancel_confirmed_order
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_number = Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      product_id = SecureRandom.uuid

      event_store.publish(Crm::CustomerRegistered.new(
        data: {
          customer_id: customer_id,
          name: "John Doe"
        }
      ))

      create_product(product_id, "Async Remote", 30)
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 30))
      run_command(Pricing::AcceptOffer.new(order_id: order_id))

      order_cancelled = Fulfillment::OrderCancelled.new(
        data: {
          order_id: order_id
        }
      )
      event_store.publish(order_cancelled)


      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Cancelled", orders.first.state)
      assert event_store.event_in_stream?(order_cancelled.event_id, "Orders$all")
    end

    private

    def create_product(product_id, name, price)
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))
      run_command(ProductCatalog::NameProduct.new(product_id: product_id, name: name))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end
  end
end
