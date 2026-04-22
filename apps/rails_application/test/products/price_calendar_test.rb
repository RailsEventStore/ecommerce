require "test_helper"

module Products
  class PriceCalendarTest < InMemoryTestCase
    cover "Products*"

    def configure(event_store, _command_bus)
      Products::Configuration.new(event_store).call
    end

    def test_price_with_default_time_returns_current_price
      product_id = SecureRandom.uuid
      register_product_with_base_price(product_id, 10)
      publish_future_price(product_id, 20, 1.hour.from_now)

      product = Products.find_by(id: product_id)

      assert_equal(BigDecimal("10"), product.price)
    end

    def test_price_at_past_time_returns_nil_when_no_price_was_valid_yet
      product_id = SecureRandom.uuid
      register_product_with_base_price(product_id, 10)

      product = Products.find_by(id: product_id)

      assert_nil(product.price(2.days.ago))
    end

    def test_price_at_future_time_returns_scheduled_price
      product_id = SecureRandom.uuid
      register_product_with_base_price(product_id, 10)
      publish_future_price(product_id, 15, 1.hour.from_now)
      publish_future_price(product_id, 20, 2.hours.from_now)

      product = Products.find_by(id: product_id)

      assert_equal(BigDecimal("15"), product.price(90.minutes.from_now))
      assert_equal(BigDecimal("20"), product.price(3.hours.from_now))
    end

    def test_future_prices_calendar_returns_only_future_prices
      product_id = SecureRandom.uuid
      register_product_with_base_price(product_id, 10)
      publish_future_price(product_id, 15, 1.hour.from_now)
      publish_future_price(product_id, 20, 2.hours.from_now)

      product = Products.find_by(id: product_id)
      future = product.future_prices_calendar

      assert_equal(2, future.length)
      assert_equal([BigDecimal("15"), BigDecimal("20")], future.map { |e| e[:price] })
    end

    def test_current_prices_calendar_parses_entries_to_time_and_big_decimal
      product_id = SecureRandom.uuid
      register_product_with_base_price(product_id, 10)

      product = Products.find_by(id: product_id)
      entry = product.current_prices_calendar.first

      assert_instance_of(ActiveSupport::TimeWithZone, entry[:valid_since])
      assert_instance_of(BigDecimal, entry[:price])
    end

    def test_current_prices_calendar_returns_empty_array_when_no_prices_set
      product_id = SecureRandom.uuid
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))

      product = Products.find_by(id: product_id)

      assert_equal([], product.current_prices_calendar)
    end

    def test_prices_are_ordered_chronologically_across_different_timezones
      product_id = SecureRandom.uuid
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))

      earlier_moment_in_utc = Time.utc(2026, 4, 22, 10, 0, 0)
      later_moment_in_negative_offset = Time.new(2026, 4, 22, 8, 0, 0, "-05:00")

      publish_future_price(product_id, 100, earlier_moment_in_utc)
      publish_future_price(product_id, 200, later_moment_in_negative_offset)

      prices = Products.find_by(id: product_id).current_prices_calendar.map { |entry| entry[:price] }

      assert_equal([BigDecimal("100"), BigDecimal("200")], prices)
    end

    def test_find_by_returns_product_matching_attributes
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      register_product_named(product_1_id, "First")
      register_product_named(product_2_id, "Second")

      assert_equal("First", Products.find_by(id: product_1_id).name)
      assert_equal("Second", Products.find_by(id: product_2_id).name)
    end

    private

    def register_product_named(product_id, name)
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: name }))
    end

    def register_product_with_base_price(product_id, price)
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
    end

    def publish_future_price(product_id, price, valid_since)
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
