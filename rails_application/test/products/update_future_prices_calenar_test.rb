require "test_helper"

module Products
  class UpdateFuturePricesCalendarTest < InMemoryTestCase
    cover "Products*"

    def test_add_future_price
      product_id = SecureRandom.uuid
      product_registered = ProductCatalog::ProductRegistered.new(data: { product_id: product_id })
      product_named = ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Async Remote" })
      event_store.publish(product_registered)
      event_store.publish(product_named)

      date_1 = DateTime.current + 1.day
      date_2 = DateTime.current + 1.month
      date_3 = DateTime.current + 1.year


      product = Product.find_by_id(product_id)
      assert_equal [], product.future_prices_calendar

      run_command(Pricing::SetFuturePrice.new(product_id: product_id, price: BigDecimal("12.01"), valid_since: date_3 ))
      run_command(Pricing::SetFuturePrice.new(product_id: product_id, price: BigDecimal(1), valid_since: date_1 ))
      run_command(Pricing::SetFuturePrice.new(product_id: product_id, price: BigDecimal(2), valid_since: date_2 ))

      product.reload
      assert_equal 3, product.future_prices_calendar.length
      assert_equal "1.0", product.future_prices_calendar[0][:price]
      assert_equal date_1.to_s, product.future_prices_calendar[0][:valid_since]
      assert_equal "2.0", product.future_prices_calendar[1][:price]
      assert_equal date_2.to_s, product.future_prices_calendar[1][:valid_since]
      assert_equal "12.01", product.future_prices_calendar[2][:price]
      assert_equal date_3.to_s, product.future_prices_calendar[2][:valid_since]
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
