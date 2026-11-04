require "test_helper"

module Orders
  class UpdateOrderTotalValueTest < InMemoryTestCase
    include ActionCable::TestHelper
    cover "Orders*"

    def configure(event_store, _command_bus)
      Orders::Configuration.new.call(event_store)
    end

    def test_order_created_when_total_value_updated
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      prepare_product(product_id)
      draft_order_in_store(order_id, store_id)

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10, items: [] }))

      order = Orders.find_order_in_store(order_id, store_id)
      assert(order)
    end

    def test_newest_event_is_always_applied
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      prepare_product(product_id)
      draft_order_in_store(order_id, store_id)
      item_added_to_basket(order_id, product_id)

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10, items: [] }, metadata: { timestamp: Time.current }))
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 10, total_amount: 20, items: [] }, metadata: { timestamp: 1.minute.ago }))

      order = Orders.find_order_in_store(order_id, store_id)
      assert_equal(10, order.total_value)
      assert_equal(0, order.discounted_value)
    end

    def test_projects_and_removes_free_product_saving
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      free_product_id = SecureRandom.uuid
      draft_order_in_store(order_id, store_id)

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id,
        discounted_amount: 30,
        total_amount: 30,
        free_product_id: free_product_id,
        free_product_saving: 10,
        items: []
      }))

      order = Orders.find_order_in_store(order_id, store_id)
      assert_equal(free_product_id, order.free_product_id)
      assert_equal(10, order.free_product_saving)

      event_store.publish(total_order_value_updated(order_id))

      order.reload
      assert_nil(order.free_product_id)
      assert_equal(0, order.free_product_saving)
    end

    def test_stream
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id)
      event = total_order_value_updated(order_id)
      event_store.publish(event)
      assert event_store.event_in_stream?(event.event_id, "Orders$all")
    end

    def test_projects_line_totals_without_order_lines_and_replaces_the_snapshot
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      other_product_id = SecureRandom.uuid
      draft_order_in_store(order_id, store_id)

      assert_equal(0, Orders.find_order_in_store(order_id, store_id).value_before_discounts)
      assert_equal(0, Orders.find_order_in_store(order_id, store_id).savings)
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id, total_amount: 90, discounted_amount: 73.21,
        free_product_id: product_id, free_product_saving: 20,
        items: [{ product_id: product_id, quantity: 4, amount: 51.11 },
                { product_id: other_product_id, quantity: 1, amount: 22.10 }]
      }))

      assert_equal(51.11.to_d, Orders.find_order_in_store(order_id, store_id).discounted_line_value(product_id))
      assert_equal(22.10.to_d, Orders.find_order_in_store(order_id, store_id).discounted_line_value(other_product_id))
      assert_equal(110, Orders.find_order_in_store(order_id, store_id).value_before_discounts)
      assert_equal(36.79.to_d, Orders.find_order_in_store(order_id, store_id).savings)

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id, total_amount: 30, discounted_amount: 27,
        items: [{ product_id: other_product_id, quantity: 1, amount: 27 }]
      }))

      assert_nil(Orders.find_order_in_store(order_id, store_id).discounted_line_value(product_id))
      assert_equal(27, Orders.find_order_in_store(order_id, store_id).discounted_line_value(other_product_id))
      assert_equal(3, Orders.find_order_in_store(order_id, store_id).savings)
    end

    def test_accepts_legacy_totals_without_items
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      draft_order_in_store(order_id, store_id)
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id, total_amount: 12, discounted_amount: 10
      }))
      assert_nil(Orders.find_order_in_store(order_id, store_id).discounted_line_value(SecureRandom.uuid))
    end

    def test_exposes_the_persisted_event_timestamp_without_changing_freshness_policy
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      draft_order_in_store(order_id, store_id)
      assert_nil(Orders.find_order_in_store(order_id, store_id).discounts_version)

      Time.use_zone("Warsaw") do
        timestamp = Time.iso8601("2026-11-04T16:00:00.123456+01:00")
        event_store.publish(Processes::TotalOrderValueUpdated.new(
          data: { order_id: order_id, total_amount: 80, discounted_amount: 60, items: [] },
          metadata: { timestamp: timestamp }))
        event_store.publish(Processes::TotalOrderValueUpdated.new(
          data: { order_id: order_id, total_amount: 80, discounted_amount: 54, items: [] },
          metadata: { timestamp: timestamp }))

        order = Orders.find_order_in_store(order_id, store_id)
        assert_equal("2026-11-04T15:00:00.123456Z", order.discounts_version)
        assert_equal(60, order.discounted_value)
      end
    end

    def test_all_discount_stream_targets_share_the_persisted_snapshot_version
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      messages = capture_broadcasts("orders_order_#{order_id}") do
        event_store.publish(Processes::TotalOrderValueUpdated.new(
          data: { order_id: order_id, total_amount: 60, discounted_amount: 54,
            free_product_id: product_id, free_product_saving: 20,
            items: [{ product_id: product_id, quantity: 4, amount: 54 }] },
          metadata: { timestamp: Time.iso8601("2026-11-04T15:00:00.123456Z") }))
      end
      updates = messages.map { |message| Nokogiri::HTML5.fragment(message).at_css("turbo-stream") }
      assert_equal([
        "orders_order_#{order_id}_total_value",
        "orders_order_#{order_id}_savings",
        "orders_order_#{order_id}_discounted_value",
        "orders_order_#{order_id}_free_product_saving_row",
        "orders_order_#{product_id}_discounted_value"
      ].sort, updates.map { |update| update["target"] }.sort)
      updates.each do |update|
        assert_equal(order_id, update["data-discounts-order"])
        assert_equal("2026-11-04T15:00:00.123456Z", update["data-discounts-version"])
      end
    end

    private

    def total_order_value_updated(order_id)
      Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10, items: [] })
    end

    def draft_order_in_store(order_id, store_id)
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))
      event_store.publish(Stores::OfferRegistered.new(data: { order_id: order_id, store_id: store_id }))
    end

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(
        data: { product_id: product_id, order_id: order_id, price: 50, base_total_value: 50, total_value: 50 }))
    end

    def prepare_product(product_id)
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: {
            product_id: product_id
          }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: {
            product_id: product_id,
            name: "test"
          }
        )
      )
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 50 }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
