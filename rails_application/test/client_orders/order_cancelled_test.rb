require "test_helper"

module ClientOrders
  class OrderCancelledTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_order_confirmed
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
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

      event_store.publish(
        Fulfillment::OrderCancelled.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal("Cancelled",  orders.first.state)
    end

    private

    def create_product(product_id, name, price)
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))
      run_command(ProductCatalog::NameProduct.new(product_id: product_id, name: name))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end
  end
end
