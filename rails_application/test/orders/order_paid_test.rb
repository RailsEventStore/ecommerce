require "test_helper"

module Orders
  class OrderConfirmedTest < InMemoryTestCase
    cover "Orders*"

    def test_order_confirmed
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_number = Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      product_id = SecureRandom.uuid

      create_product(product_id, "Async Remote", 10)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "John Doe" }))
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 10,
            price: 10,
            base_total_value: 10,
            total_value: 10
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
        Crm::CustomerAssignedToOrder.new(data: { customer_id: customer_id, order_id: order_id })
      )

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10 }))
      order_confirmed = Fulfillment::OrderConfirmed.new(
        data: {
          order_id: order_id
        }
      )
      event_store.publish(order_confirmed)

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Paid", orders.first.state)
      assert event_store.event_in_stream?(order_confirmed.event_id, "Orders$all")
    end

    private

    def create_product(product_id, name, price)
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: name }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
