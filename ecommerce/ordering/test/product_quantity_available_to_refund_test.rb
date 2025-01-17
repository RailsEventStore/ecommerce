require_relative "test_helper"

module Ordering
  class ProductQuantityAvailableToRefundTest < Test
    cover "Ordering::ProductQuantityAvailableToRefund"

    def test_product_quantity_available_to_refund
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid
      stream_name = "Ordering::Order$#{order_id}"
      projection = ProductQuantityAvailableToRefund.call(order_id, product_id)

      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

      event_store.publish(ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_id }), stream_name: stream_name)
      event_store.publish(ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_id }), stream_name: stream_name)
      event_store.publish(ItemRemovedFromBasket.new(data: { order_id: order_id, product_id: product_id }), stream_name: stream_name)
      event_store.publish(ItemAddedToBasket.new(data: { order_id: order_id, product_id: another_product_id }), stream_name: stream_name)
      event_store.publish(ItemRemovedFromBasket.new(data: { order_id: order_id, product_id: another_product_id }), stream_name: stream_name)

      available_quantity_to_refund = projection.run(event_store)

      assert_equal({ available: 1 }, available_quantity_to_refund)
    end
  end
end
