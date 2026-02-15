require "test_helper"

module ClientOrders
  class UpdateOrderTotalValueTest < InMemoryTestCase
    include ActionCable::TestHelper
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_order_created_has_draft_state
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)

      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10, items: [] }))

      order = ClientOrders::Order.find_by(order_uid: order_id)
      assert_equal "Draft", order.state
    end

    def test_broadcasts
      order_id = SecureRandom.uuid
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

    private

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
