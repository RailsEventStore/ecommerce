require "test_helper"

module ClientOrders
  class OrderExpiredTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_order_expired
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

      event_store.publish(Crm::CustomerRegistered.new(
        data: {
          customer_id: customer_id,
          name: "John Doe"
        }
      ))

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
          }
        )
      )

      event_store.publish(
        Pricing::OfferExpired.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal("Expired", orders.first.state)
    end
  end
end
