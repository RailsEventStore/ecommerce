require_relative "test_helper"

module Pricing
  class SubAmounts < Test

    def test_calculates_sub_amounts
      set_price(product_id, 20)

      assert_events_contain(stream, price_item_value_calculated_event(20, 20))  do
        add_item(order_id, product_id)
      end
    end

    private

    def price_item_value_calculated_event(amount, discounted_amount)
      PriceItemValueCalculated.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          quantity: 1,
          discounted_amount: discounted_amount,
          amount: amount
        }
      )
    end

    def stream
      "Pricing::Order$#{order_id}"
    end

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def order_id
      @order_id ||= SecureRandom.uuid
    end

  end
end
