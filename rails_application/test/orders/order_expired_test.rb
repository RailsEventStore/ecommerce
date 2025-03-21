require "test_helper"

module Orders
  class OrderExpiredTest < InMemoryTestCase
    cover "Orders*"

    def test_expire_created_order
      event_store = Rails.configuration.event_store

      customer_id = SecureRandom.uuid
      run_command(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      )
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

      order_id = SecureRandom.uuid
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 39,
            catalog_price: 39
          }
        )
      )

      order_expired = Pricing::OfferExpired.new(data: { order_id: order_id })
      event_store.publish(order_expired)

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Expired")
      assert event_store.event_in_stream?(order_expired.event_id, "Orders$all")
    end
  end
end
