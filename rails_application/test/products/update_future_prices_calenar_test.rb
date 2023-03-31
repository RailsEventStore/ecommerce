require "test_helper"

module Products
  class UpdateFuturePricesCalendarTest < InMemoryTestCase
    cover "Products*"

    def test_add_future_price
      product_id = SecureRandom.uuid
      product_registered = ProductCatalog::ProductRegistered.new(data: { product_id: product_id })
      product_named = ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Async Remote" })
      set_price = Pricing::PriceSet.new(data: { product_id: product_id, price: 10 })
      event_store.publish(product_registered)
      event_store.publish(product_named)
      event_store.publish(set_price)

      date_1 = 1.hour.from_now
      date_2 = 2.hours.from_now
      date_3 = 3.hours.from_now

      product = Product.find_by_id(product_id)
      assert_equal [], product.future_prices_calendar

      run_command(Pricing::SetFuturePrice.new(product_id: product_id, price: BigDecimal("12.01"), valid_since: date_3 ))
      run_command(Pricing::SetFuturePrice.new(product_id: product_id, price: BigDecimal("1.0"), valid_since: date_1 ))
      run_command(Pricing::SetFuturePrice.new(product_id: product_id, price: BigDecimal("2.0"), valid_since: date_2 ))

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

    def event_store
      Rails.configuration.event_store
    end
  end
end
