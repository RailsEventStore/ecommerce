require_relative "test_helper"

module Pricing
  class SimpleOfferTest < Test
    cover "Pricing::Offer*"

    def test_adding
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

    end

    def test_removing
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_id)
      add_item(order_id, product_id)
      stream = "Pricing::Offer$#{order_id}"

      assert_events(
        stream,
        PriceItemRemoved.new(
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
      ) { remove_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 0,
            total_value: 0,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 0,
            total_amount: 0
          }
        )
      ) { remove_item(order_id, product_id) }
    end
  end
end
