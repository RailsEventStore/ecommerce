require "test_helper"

module ClientOrders
  class UpdateOrderTotalValueTest < InMemoryTestCase
    include ActionCable::TestHelper
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      event_store.subscribe(OrderHandlers::DraftOrder.new, to: [Pricing::OfferDrafted])
      event_store.subscribe(
        OrderHandlers::UpdateOrderTotalValue.new,
        to: [Processes::TotalOrderValueUpdated]
      )
    end

    def test_order_created_has_draft_state
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10, items: [] }))

      assert_equal("Draft", ClientOrders.find_order(order_id).state)
    end

    def test_broadcasts
      order_id = SecureRandom.uuid
      draft_order(order_id)
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10, items: [] }))

      assert_broadcast_on(
        "client_orders_#{order_id}",
        turbo_stream_action_tag(
          action: "update",
          target: "client_orders_#{order_id}_total_value",
          order_id: order_id,
          template: "$10.00"
        )
      )
      assert_broadcast_on(
        "client_orders_#{order_id}",
        turbo_stream_action_tag(
          action: "update",
          target: "client_orders_#{order_id}_discounted_value",
          order_id: order_id,
          template: "$0.00"
        )
      )
    end

    def test_projects_and_removes_free_product_saving
      order_id = SecureRandom.uuid
      draft_order(order_id)
      free_product_id = SecureRandom.uuid

      event_store.publish(total_order_value_updated(order_id, free_product_id, 10))

      assert_equal(free_product_id, ClientOrders.find_order(order_id).free_product_id)
      assert_equal(10, ClientOrders.find_order(order_id).free_product_saving)

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id,
        discounted_amount: 40,
        total_amount: 40,
        items: []
      }))

      assert_nil(ClientOrders.find_order(order_id).free_product_id)
      assert_equal(0, ClientOrders.find_order(order_id).free_product_saving)
    end

    def test_broadcasts_free_product_saving_appearing_changing_and_disappearing
      order_id = SecureRandom.uuid
      draft_order(order_id)

      event_store.publish(total_order_value_updated(order_id, SecureRandom.uuid, 20))
      assert_free_product_saving_broadcast(order_id, "$20.00")

      event_store.publish(total_order_value_updated(order_id, SecureRandom.uuid, 10))
      assert_free_product_saving_broadcast(order_id, "$10.00")

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id,
        discounted_amount: 40,
        total_amount: 40,
        items: []
      }))
      assert_broadcast_on(
        "client_orders_#{order_id}",
        turbo_stream_action_tag(
          action: "update",
          target: "client_orders_#{order_id}_free_product_saving_row",
          order_id: order_id,
          template: ""
        )
      )
    end

    def test_projects_line_totals_without_order_lines_and_clears_removed_products
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      other_product_id = SecureRandom.uuid
      draft_order(order_id)
      assert_equal(0, ClientOrders.find_order(order_id).value_before_discounts)
      assert_equal(0, ClientOrders.find_order(order_id).savings)
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id, total_amount: 90, discounted_amount: 73.21,
        free_product_id: product_id, free_product_saving: 20,
        items: [{ product_id: product_id, quantity: 4, amount: 51.11 },
                { product_id: other_product_id, quantity: 1, amount: 22.10 }]
      }))

      assert_equal(51.11.to_d, ClientOrders.find_order(order_id).discounted_line_value(product_id))
      assert_equal(22.10.to_d, ClientOrders.find_order(order_id).discounted_line_value(other_product_id))
      assert_equal(110, ClientOrders.find_order(order_id).value_before_discounts)
      assert_equal(36.79.to_d, ClientOrders.find_order(order_id).savings)
      assert_broadcast_on("client_orders_#{order_id}", turbo_stream_action_tag(
        action: "update", target: "client_orders_#{product_id}_discounted_value", template: "$51.11", order_id: order_id
      ))
      assert_broadcast_on("client_orders_#{order_id}", turbo_stream_action_tag(
        action: "update", target: "client_orders_#{order_id}_savings", template: "$36.79", order_id: order_id
      ))

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id, total_amount: 30, discounted_amount: 27,
        items: [{ product_id: other_product_id, quantity: 1, amount: 27 }]
      }))

      assert_nil(ClientOrders.find_order(order_id).discounted_line_value(product_id))
      assert_equal(27, ClientOrders.find_order(order_id).discounted_line_value(other_product_id))
      assert_equal(3, ClientOrders.find_order(order_id).savings)
      assert_broadcast_on("client_orders_#{order_id}", turbo_stream_action_tag(
        action: "update", target: "client_orders_#{product_id}_discounted_value", template: "—", order_id: order_id
      ))
    end

    def test_accepts_legacy_totals_without_items
      order_id = SecureRandom.uuid
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id, total_amount: 12, discounted_amount: 10
      }))
      assert_equal("Draft", ClientOrders.find_order(order_id).state)
      assert_nil(ClientOrders.find_order(order_id).discounted_line_value(SecureRandom.uuid))
    end

    def test_exposes_save_time_while_still_accepting_equal_event_timestamps
      order_id = SecureRandom.uuid
      assert_nil(Order.new.discounts_version)
      timestamp = Time.iso8601("2026-11-04T15:00:00.000000Z")

      Time.use_zone("Warsaw") do
        travel_to(Time.iso8601("2026-11-04T16:00:00.123456+01:00"), with_usec: true) do
          event_store.publish(Processes::TotalOrderValueUpdated.new(
            data: { order_id: order_id, total_amount: 80, discounted_amount: 60, items: [] },
            metadata: { timestamp: timestamp }))
        end
        travel_to(Time.iso8601("2026-11-04T16:00:00.123457+01:00"), with_usec: true) do
          event_store.publish(Processes::TotalOrderValueUpdated.new(
            data: { order_id: order_id, total_amount: 80, discounted_amount: 54, items: [] },
            metadata: { timestamp: timestamp }))
        end

        order = ClientOrders.find_order(order_id)
        assert_equal("2026-11-04T15:00:00.123457Z", order.discounts_version)
        assert_equal(54, order.discounted_value)
      end
    end

    private

    def draft_order(order_id)
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))
    end

    def total_order_value_updated(order_id, free_product_id, free_product_saving)
      Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id,
        discounted_amount: 30,
        total_amount: 30,
        free_product_id: free_product_id,
        free_product_saving: free_product_saving,
        items: []
      })
    end

    def assert_free_product_saving_broadcast(order_id, saving)
      assert_broadcast_on(
        "client_orders_#{order_id}",
        turbo_stream_action_tag(
          action: "update",
          target: "client_orders_#{order_id}_free_product_saving_row",
          order_id: order_id,
          template: %(<td class="py-2" colspan="5">3+1 — cheapest item free</td>\n<td class="py-2">-#{saving}</td>\n)
        )
      )
    end

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(data: { product_id: product_id, order_id: order_id }))
    end

    def prepare_product(product_id)
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "test" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 50 }))
    end

    def customer_registered(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def event_store
      Rails.configuration.event_store
    end

    def turbo_stream_action_tag(action:, target:, template:, order_id:)
      version = ClientOrders.find_order(order_id).updated_at.utc.iso8601(6)
      "<turbo-stream data-discounts-order=\"#{order_id}\" data-discounts-version=\"#{version}\" action=\"#{action}\" target=\"#{target}\"><template>#{template}</template></turbo-stream>"
    end
  end
end
