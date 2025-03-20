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
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      in_memory_broadcast.result.clear

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20
          }
        )
      )

      [
        { stream_id: order_id, target_id: product_id, target: "quantity", content: 1 },
        { stream_id: order_id, target_id: product_id, target: "value", content: "$20.00" },
        { :stream_id => order_id, :target_id => order_id, :target => "total_value", :content => "$20.00" },
        { :stream_id => order_id, :target_id => order_id, :target => "discounted_value", :content => "$20.00" }
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
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      order_id = SecureRandom.uuid

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        )
      )
      in_memory_broadcast.result.clear

      event_store.publish(
        Pricing::PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        )
      )

      [
        { stream_id: order_id, target_id: product_id, target: "quantity", content: 0 },
        { stream_id: order_id, target_id: product_id, target: "value", content: nil },
        { :stream_id => order_id, :target_id => order_id, :target => "total_value", :content => "$0.00" },
        { :stream_id => order_id, :target_id => order_id, :target => "discounted_value", :content => "$0.00" }
      ].each do |expected_broadcast|
        assert_includes in_memory_broadcast.result, expected_broadcast
      end
    end

    def test_broadcast_update_discount
      skip "it looks, like it's not possible to update discount without full RELOAD"
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_1_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20
          }
        )
      )
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_1_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20
          }
        )
      )

      event_store.publish(
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_1_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 30
          }
        )
      )

      in_memory_broadcast.result.clear

      event_store.publish(
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
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
