require "test_helper"

module ClientOrders
  class UpdateOrderTotalValueTest < InMemoryTestCase
    include ActionCable::TestHelper
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      event_store.subscribe(
        OrderHandlers::UpdateOrderTotalValue.new,
        to: [Processes::TotalOrderValueUpdated]
      )
    end

    def test_order_created_has_draft_state
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      draft_order(order_id)
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
          template: "$10.00"
        )
      )
      assert_broadcast_on(
        "client_orders_#{order_id}",
        turbo_stream_action_tag(
          action: "update",
          target: "client_orders_#{order_id}_discounted_value",
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
          template: ""
        )
      )
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
          template: %(<td class="py-2" colspan="4">3+1 — cheapest item free</td>\n<td class="py-2">-#{saving}</td>\n)
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

    def turbo_stream_action_tag(action:, target:, template:)
      "<turbo-stream action=\"#{action}\" target=\"#{target}\"><template>#{template}</template></turbo-stream>"
    end
  end
end
