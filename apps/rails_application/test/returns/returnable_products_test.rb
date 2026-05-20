require "test_helper"

module Returns
  class ReturnableProductsTest < InMemoryTestCase
    cover "Returns::ReturnableProducts"

    def configure(event_store, command_bus)
    end

    def test_returns_order_lines_from_latest_accepted_offer_when_order_placed
      order_id = SecureRandom.uuid
      other_order_id = SecureRandom.uuid
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      product_3_id = SecureRandom.uuid

      event_store.publish(
        [
          Pricing::OfferAccepted.new(
            data: {
              order_id: order_id,
              order_lines: [
                { product_id: product_3_id, quantity: 1 },
                { product_id: product_1_id, quantity: 1 },
                { product_id: product_2_id, quantity: 2 },
              ]
            }
          ),
          Pricing::OfferAccepted.new(
            data: {
              order_id: order_id,
              order_lines: [
                { product_id: product_1_id, quantity: 1 },
                { product_id: product_2_id, quantity: 1 },
              ]
            }
          ),
          Pricing::PriceItemAdded.new(
            data: { order_id: order_id, product_id: product_1_id, base_price: 10, price: 10 }
          ),
        ],
        stream_name: "Pricing::Offer$#{order_id}"
      )
      event_store.publish(
        [
          Pricing::OfferAccepted.new(
            data: {
              order_id: other_order_id,
              order_lines: [{ product_id: SecureRandom.uuid, quantity: 9 }]
            }
          ),
        ],
        stream_name: "Pricing::Offer$#{other_order_id}"
      )
      event_store.publish(
        [Fulfillment::OrderRegistered.new(data: { order_id: order_id, order_number: "2024/01/1" })],
        stream_name: "Fulfillment::Order$#{order_id}"
      )

      result = ReturnableProducts.new.call(event_store, order_id)

      assert_equal(
        [{ product_id: product_1_id, quantity: 1 }, { product_id: product_2_id, quantity: 1 }],
        result
      )
    end

    def test_returns_nil_when_order_not_placed
      order_id = SecureRandom.uuid

      event_store.publish(
        [
          Pricing::OfferAccepted.new(
            data: {
              order_id: order_id,
              order_lines: [{ product_id: SecureRandom.uuid, quantity: 1 }]
            }
          ),
        ],
        stream_name: "Pricing::Offer$#{order_id}"
      )

      assert_nil(ReturnableProducts.new.call(event_store, order_id))
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
