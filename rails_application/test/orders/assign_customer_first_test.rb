require "test_helper"

module Orders
  class AssignCustomerFirstTest < InMemoryTestCase
    cover "Orders*"

    def setup
      super
      Order.destroy_all
      OrderLine.destroy_all
    end

    def test_create_draft_order_when_not_exists
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      customer_registered = Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "dummy" })
      event_store.publish(customer_registered)
      customer_assigned_to_order = Crm::CustomerAssignedToOrder.new(data: { order_id: SecureRandom.uuid, customer_id: customer_id })
      event_store.publish(
        customer_assigned_to_order
      )
      assert_equal(Order.count, 1)
      assert event_store.event_in_stream?(customer_assigned_to_order.event_id, "Orders$all")
      assert event_store.event_in_stream?(customer_registered.event_id, "Orders$all")
    end
  end
end