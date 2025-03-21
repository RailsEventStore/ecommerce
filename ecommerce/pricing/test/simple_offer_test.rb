require_relative "test_helper"

module Pricing
  class SimpleOfferTest < Test
    cover "Pricing*"

    def test_adding_offer_item
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)
      assert_events_contain(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            catalog_price: 20,
            price: 20
          }
        )
      ) { add_item(order_id, product_id) }
    end

    def test_removing_offer_item
      product_id = SecureRandom.uuid
      set_price(product_id, 30)
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)
      add_item(order_id, product_id)

      assert_events_contain(
        stream,
        PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            catalog_price: 30,
            price: 30
          }
        )
      ) { remove_item(order_id, product_id, 30) }
    end

    private

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end
  end
end
