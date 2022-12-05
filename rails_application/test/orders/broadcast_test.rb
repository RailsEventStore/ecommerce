require "test_helper"

module Orders
  class BroadcastTest < InMemoryTestCase
    cover "Orders*"

    def setup
      @prev = Rails.configuration.read_model
      Rails.configuration.read_model = InMemoryBroadcaster.new
    end

    def teardown
      Rails.configuration.read_model = @prev
    end

    class InMemoryBroadcaster
      def initialize
        @result = []
      end

      attr_accessor :result

      def broadcast_update(order_id, product_id, target, content)
        result << { order_id: order_id, product_id: product_id, target: target, content: content }
      end

      def link_event_to_stream(event) end
    end

    def test_broadcast
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

      expected_broadcasts = [
        { order_id: order_id, product_id: product_id, target: "quantity", content: 1 },
        { order_id: order_id, product_id: product_id, target: "value", content: "$20.00" }
      ]

      assert_equal in_memory_broadcast.result, expected_broadcasts
    end

    private

    def in_memory_broadcast
      Rails.configuration.read_model
    end
  end
end
