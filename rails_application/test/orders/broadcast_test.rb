require "test_helper"

module Orders
  class BroadcastTest < InMemoryTestCase
    cover "Orders*"

    def setup
      @prev = Rails.configuration.broadcaster
      Rails.configuration.broadcaster = InMemoryBroadcaster.new
    end

    def teardown
      Rails.configuration.broadcaster = @prev
    end

    class InMemoryBroadcaster
      def initialize
        @result = []
      end

      attr_accessor :result

      def broadcast_update(order_id, product_id, target, content)
        result << { order_id: order_id, product_id: product_id, target: target, content: content }
      end
    end

    def test_broadcast_add_item_to_basket
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )

      expected_broadcasts = [
        { order_id: order_id, product_id: product_id, target: "quantity", content: 1 },
        { order_id: order_id, product_id: product_id, target: "value", content: "$20.00" }
      ]

      assert in_memory_broadcast.result.intersect?(expected_broadcasts)
    end

    def test_broadcast_remove_item_from_basket
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      order_id = SecureRandom.uuid

      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )
      in_memory_broadcast.result.clear

      event_store.publish(
        Ordering::ItemRemovedFromBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
          }
        )
      )

      expected_broadcasts = [
        { order_id: order_id, product_id: product_id, target: "quantity", content: 0 },
        { order_id: order_id, product_id: product_id, target: "value", content: "$0.00" }
      ]

      assert in_memory_broadcast.result.intersect?(expected_broadcasts)
    end

    private

    def in_memory_broadcast
      Rails.configuration.broadcaster
    end
  end
end
