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
            price: 20
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
            price: 20
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
            price: 20
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
            price: 20
          }
        )
      ) { remove_item(order_id, product_id) }
    end
  end
end
