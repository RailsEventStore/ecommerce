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
      event_store.publish(Pricing::PriceItemAdded.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          base_price: 30,
          price: 30,
          base_total_value: 30,
          total_value: 30
        }
      ))
      event_store.publish(Pricing::OfferAccepted.new(
        data: {
          order_id: order_id,
          order_lines: [{ product_id: product_id, quantity: 1 }]
        }
      ))

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
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: name }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
