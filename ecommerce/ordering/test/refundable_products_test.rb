require_relative "test_helper"

module Ordering
  class RefundableProductsTest < Test
    cover "Ordering::RefundableProducts"

    def test_product_quantity_available_to_refund
      order_id = SecureRandom.uuid
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      product_3_id = SecureRandom.uuid
      stream_name = "Ordering::Order$#{order_id}"
      projection = RefundableProducts.call(order_id)

      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

      event_store.publish(ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_3_id }), stream_name: stream_name)
      event_store.publish(ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_1_id }), stream_name: stream_name)
      event_store.publish(ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_2_id }), stream_name: stream_name)
      event_store.publish(ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_2_id }), stream_name: stream_name)
      event_store.publish(ItemRemovedFromBasket.new(data: { order_id: order_id, product_id: product_2_id }), stream_name: stream_name)
      event_store.publish(ItemRemovedFromBasket.new(data: { order_id: order_id, product_id: product_3_id }), stream_name: stream_name)

      refundable_products = projection.run(event_store)

      assert_equal([{ product_id: product_1_id, quantity: 1}, {product_id: product_2_id, quantity: 1 }], refundable_products)
    end
  end
end
