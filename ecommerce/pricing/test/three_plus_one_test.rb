require_relative "test_helper"

module Pricing
  class ThreePlusOneTest < Test
    cover "Pricing::Offer*"

    def test_given_three_items_are_added_when_forth_item_is_added_then_the_last__item_is_free
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"
      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 20,
            total_value: 20,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 20,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 40,
            total_value: 40,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 40,
            total_amount: 40
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 2,
            amount: 40,
            discounted_amount: 40,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 60,
            total_value: 60,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 60
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 3,
            amount: 60,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 0,
            base_total_value: 80,
            total_value: 60,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 80
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 4,
            amount: 80,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id) }
    end

    def test_given_3_plus_one__when_10_percent_discount_for_offer__then_offer_price_includes_both_discounts
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"
      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 20,
            total_value: 20,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 20,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 40,
            total_value: 40,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 40,
            total_amount: 40
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 2,
            amount: 40,
            discounted_amount: 40,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 60,
            total_value: 60,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 60
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 3,
            amount: 60,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 0,
            base_total_value: 80,
            total_value: 60,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 80
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 4,
            amount: 80,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id) }
    end
  end
end
