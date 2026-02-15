require "test_helper"

module Products
  class UpdateFuturePricesCalendarTest < InMemoryTestCase
    cover "Products*"

    def configure(event_store, command_bus)
      Products::Configuration.new(event_store).call
    end

    def test_add_future_price
      product_id = SecureRandom.uuid
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Async Remote" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 10 }))

      date_1 = 1.hour.from_now
      date_2 = 2.hours.from_now
      date_3 = 3.hours.from_now

      product = Product.find_by_id(product_id)
      assert_equal [], product.future_prices_calendar

      publish_price_set(product_id, BigDecimal("12.01"), date_3)
      publish_price_set(product_id, BigDecimal("1.0"), date_1)
      publish_price_set(product_id, BigDecimal("2.0"), date_2)

      product.reload
      assert_equal 4, product.current_prices_calendar.length
      assert_equal [
        BigDecimal("10.0"),
        BigDecimal("1.0"),
        BigDecimal("2.0"),
        BigDecimal("12.01")
      ], product.current_prices_calendar.map { |e| e[:price] }
    end

    private

    def publish_price_set(product_id, price, valid_since)
      event_store.publish(
        Pricing::PriceSet.new(
          data: { product_id: product_id, price: price },
          metadata: { valid_at: valid_since }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
