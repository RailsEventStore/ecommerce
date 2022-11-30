require_relative "test_helper"

module Pricing
  class FuturePricesTest < Test
    cover "Pricing*"

    def test_future_price_is_not_included_when_calculating_total_value
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      future_date_timestamp = Time.now.utc + plus_five_days
      set_future_price(product_1_id, 30, future_date_timestamp.to_s)
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
      future_date_timestamp = Time.now.utc + plus_five_days
      set_future_price(product_1_id, 30, future_date_timestamp.to_s)

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

    private

    def plus_five_days
      3600 * 24 * 5
    end

  end
end
