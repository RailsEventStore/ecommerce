require_relative "test_helper"

module Pricing
  class FuturePricesTest < Test
    cover "Pricing*"

    def test_future_price_is_not_included_when_calculating_total_value
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      future_date_timestamp = Time.current + days_number(5)
      set_future_price(product_1_id, 30, future_date_timestamp)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = "Pricing::Order$#{order_id}"

      assert_events(
        stream,
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        )
      ) { calculate_total_value(order_id) }
    end

    def test_check_future_price
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      future_date_timestamp = Time.current + days_number(5)
      set_future_price(product_1_id, 30, future_date_timestamp)

      Timecop.travel(future_date_timestamp + 2137) do
        order_id = SecureRandom.uuid
        add_item(order_id, product_1_id)
        stream = "Pricing::Order$#{order_id}"

        assert_events(
          stream,
          OrderTotalValueCalculated.new(
            data: {
              order_id: order_id,
              discounted_amount: 30,
              total_amount: 30
            }
          )
        ) { calculate_total_value(order_id) }
      end
    end

    def test_future_prices_catalog_by_product_id
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      future_date_timestamp_1 = with_precision(Time.current + days_number(2))
      future_date_timestamp_2 = with_precision(Time.current + days_number(3))
      future_date_timestamp_3 = with_precision(Time.current + days_number(4))

      set_future_price(product_id, 30, future_date_timestamp_3)
      set_future_price(product_id, 40, future_date_timestamp_1)
      set_future_price(product_id, 50, future_date_timestamp_2)

      pricing_catalog = PricingCatalog.new(event_store)

      assert_equal 20, pricing_catalog.price_by_product_id(product_id)

      assert_equal [
        BigDecimal(20),
        BigDecimal(40),
        BigDecimal(50),
        BigDecimal(30)
      ], pricing_catalog.current_prices_catalog_by_product_id(product_id).map { |entry| entry[:price] }

      Timecop.travel(future_date_timestamp_1 + 1.second) do
        assert_equal [
          BigDecimal(40),
          BigDecimal(50),
          BigDecimal(30)
        ], pricing_catalog.current_prices_catalog_by_product_id(product_id).map { |entry| entry[:price] }
        assert_equal [
          future_date_timestamp_1,
          future_date_timestamp_2,
          future_date_timestamp_3,
        ], pricing_catalog.current_prices_catalog_by_product_id(product_id).map { |entry| entry[:valid_since] }
        assert_equal BigDecimal(40), pricing_catalog.price_by_product_id(product_id)
      end

      Timecop.travel(future_date_timestamp_2 + 1.second) do
        assert_equal [
          BigDecimal(50),
          BigDecimal(30)
        ], pricing_catalog.current_prices_catalog_by_product_id(product_id).map { |entry| entry[:price] }
        assert_equal [
          future_date_timestamp_2,
          future_date_timestamp_3,
        ], pricing_catalog.current_prices_catalog_by_product_id(product_id).map { |entry| entry[:valid_since] }
        assert_equal BigDecimal(50), pricing_catalog.price_by_product_id(product_id)
      end


      pricing_catalog = PricingCatalog.new(event_store)
      Timecop.travel(future_date_timestamp_3 + 1.second) do
        assert_equal [BigDecimal(30)], pricing_catalog.current_prices_catalog_by_product_id(product_id).map { |entry| entry[:price] }
        assert_equal [
          future_date_timestamp_3
        ], pricing_catalog.current_prices_catalog_by_product_id(product_id).map { |entry| entry[:valid_since] }
        assert_equal BigDecimal(30), pricing_catalog.price_by_product_id(product_id)
      end
    end

    private

    def days_number(n)
      3600 * 24 * n
    end

    def with_precision(time)
      time.round(6)
    end
  end
end
