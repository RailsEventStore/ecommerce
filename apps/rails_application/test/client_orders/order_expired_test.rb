require "test_helper"

module ClientOrders
  class OrderExpiredTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_order_expired
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Async Remote" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 39 }))

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
            base_price: 39,
            price: 39,
            base_total_value: 39,
            total_value: 39,
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

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
