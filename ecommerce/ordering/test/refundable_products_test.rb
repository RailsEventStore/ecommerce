require_relative "test_helper"

module Ordering
  class RefundableProductsTest < Test
    cover "Ordering::RefundableProducts"

    def test_product_quantity_available_to_refund
      order_id = SecureRandom.uuid
      order_number = Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      product_3_id = SecureRandom.uuid
      stream_name = "Pricing::Offer$#{order_id}"

      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

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
            }),
          Pricing::OfferAccepted.new(
            data: {
              order_id: order_id,
              order_lines: [
                { product_id: product_1_id, quantity: 1 },
                { product_id: product_2_id, quantity: 1 }
              ]
            }
          ),
        ],
        stream_name: stream_name
      )
      event_store.publish(
        [Fulfillment::OrderRegistered.new(data: { order_id:, order_number: })],
        stream_name: "Fulfillment::Order$#{order_id}"
      )

      refundable_products = RefundableProducts.new.call(event_store, order_id)

      assert_equal([{ product_id: product_1_id, quantity: 1 }, { product_id: product_2_id, quantity: 1 }], refundable_products)
    end

    def test_order_have_to_be_placed
      order_id = SecureRandom.uuid
      stream_name = "Pricing::Offer$#{order_id}"

      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

      event_store.publish(
        [
          Pricing::OfferAccepted.new(
            data: {
              order_id: order_id,
              order_lines: [
                { product_id: SecureRandom.uuid, quantity: 1 },
                { product_id: SecureRandom.uuid, quantity: 1 },
              ]
            }),
        ],
        stream_name: stream_name)

      assert_nil(RefundableProducts.new.call(event_store, order_id))
    end
  end
end
