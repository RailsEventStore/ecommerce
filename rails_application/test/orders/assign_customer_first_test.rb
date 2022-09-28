require "test_helper"

module Orders
  class AssignCustomerFirstTest < InMemoryTestCase
    cover "Orders"

    def setup
      super
      Order.destroy_all
      OrderLine.destroy_all
    end

    def test_create_draft_order_when_not_exists
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "dummy" }))
      event_store.publish(
        Crm::CustomerAssignedToOrder.new(data: { order_id: SecureRandom.uuid, customer_id: customer_id })
      )
      assert_equal(Order.count, 1)
    end
  end
end