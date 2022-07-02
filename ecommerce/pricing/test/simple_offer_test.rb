require_relative "test_helper"

module Pricing
  class SimpleOfferTest < Test
    cover "Pricing*"

    def test_removing
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
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
      remove_item(order_id, product_1_id)
      assert_events(
        stream,
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 0,
            total_amount: 0
          }
        )
      ) { calculate_total_value(order_id) }
    end
  end
end
