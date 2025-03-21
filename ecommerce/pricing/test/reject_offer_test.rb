require_relative "test_helper"

module Pricing
  class AcceptOfferTest < Test
    cover "Pricing*"

    def test_accepting_offer_happy_path
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      set_price(product_2_id, 35)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_2_id)
      add_item(order_id, product_2_id)
      stream = stream_name(order_id)
      assert_events_contain(
        stream,
        OfferAccepted.new(
          data: {
            order_id: order_id,
            amount: 20 + 2 * 35,
            order_items: [
              { product_id: product_1_id, price: 20, catalog_price: 20 },
              { product_id: product_2_id, price: 35, catalog_price: 35 },
              { product_id: product_2_id, price: 35, catalog_price: 35 }
            ]
          }
        )
      ) { accept_offer(order_id) }
    end

    def test_not_possible_to_change_accepted_offer
      product_id = SecureRandom.uuid
      set_price(product_id, 111)
      order_id = SecureRandom.uuid
      add_item(order_id, product_id)
      set_percentage_discount(order_id, 33)
      accept_offer(order_id)

      assert_raises(CantModifyAcceptedOffer) { add_item(order_id, product_id) }
      assert_raises(CantModifyAcceptedOffer) { remove_item(order_id, product_id, 111) }
      assert_raises(CantModifyAcceptedOffer) { set_percentage_discount(order_id, 44) }
      assert_raises(CantModifyAcceptedOffer) { remove_percentage_discount(order_id) }
      assert_raises(CantModifyAcceptedOffer) { use_coupon(order_id, SecureRandom.uuid, 20) }
    end

    private

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end

    def accept_offer(order_id)
      run_command(AcceptOffer.new(order_id: order_id))
    end
  end
end
