require "test_helper"

module ClientOrders
  class OrderConfirmedTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_order_confirmed
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "John Doe" }))
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Async Remote" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 30 }))

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 30,
            price: 30,
            base_total_value: 30,
            total_value: 30,
          }
        )
      )

      event_store.publish(
        Processes::TotalOrderValueUpdated.new(
          data: {
            order_id: order_id,
            discounted_amount: 30,
            total_amount: 30,
            items: [ { product_id: product_id, quantity: 1, amount: 30 } ]
          }
        )
      )

      event_store.publish(
        Pricing::OfferAccepted.new(
          data: {
            order_id: order_id,
            order_lines: [{ product_id: product_id, quantity: 1 }]
          }
        )
      )

      event_store.publish(
        Crm::CustomerAssignedToOrder.new(
          data: {
            customer_id: customer_id,
            order_id: order_id
          }
        )
      )

      event_store.publish(
        Fulfillment::OrderConfirmed.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal("Paid",  orders.first.state)
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
