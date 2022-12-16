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

      def call(stream_id, target_id, target, content)
        result << { stream_id: stream_id, target_id: target_id, target: target, content: content }
      end
    end

    def test_broadcast_add_item_to_basket
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      in_memory_broadcast.result.clear

      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )

      [
        { stream_id: order_id, target_id: product_id, target: "quantity", content: 1 },
        { stream_id: order_id, target_id: product_id, target: "value", content: "$20.00" }
      ].each { |expected_broadcast| assert_includes in_memory_broadcast.result, expected_broadcast }
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

      [
        { stream_id: order_id, target_id: product_id, target: "quantity", content: 0 },
        { stream_id: order_id, target_id: product_id, target: "value", content: "$0.00" }
      ].each do |expected_broadcast|
        assert_includes in_memory_broadcast.result, expected_broadcast
      end
    end

    def test_broadcast_update_order_value
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_1_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )
      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_1_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )

      event_store.publish(
        Pricing::OrderTotalValueCalculated.new(
          data: {
            order_id: order_1_id,
            discounted_amount: 30,
            total_amount: 30
          }
        )
      )

      in_memory_broadcast.result.clear

      event_store.publish(
        Pricing::OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 30,
            total_amount: 30
          }
        )
      )

      assert_equal 2, in_memory_broadcast.result.size
      [
        { :stream_id => order_id, :target_id => order_id, :target => "total_value", :content => "$30.00" },
        { :stream_id => order_id, :target_id => order_id, :target => "discounted_value", :content => "$30.00" }
      ].each do |expected_broadcast|
        assert_includes in_memory_broadcast.result, expected_broadcast
      end
    end

    def test_broadcast_update_discount
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_1_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )
      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_1_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )

      event_store.publish(
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_1_id,
            amount: 30
          }
        )
      )

      in_memory_broadcast.result.clear

      event_store.publish(
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            amount: 30
          }
        )
      )

      assert_equal 3, in_memory_broadcast.result.size
      [
        { :stream_id => order_id, :target_id => order_id, :target => "percentage_discount", :content => 30 },
      ].each do |expected_broadcast|
        assert_includes in_memory_broadcast.result, expected_broadcast
      end
    end

    private

    def in_memory_broadcast
      Rails.configuration.broadcaster
    end
  end
end
