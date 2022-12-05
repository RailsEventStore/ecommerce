require "test_helper"

module Orders
  class CustomerRegisteredTest < InMemoryTestCase
    cover "Orders*"

    def setup
      super
      Customer.destroy_all
    end

    def test_customer_registered
      event_store = Rails.configuration.event_store

      customer_id = SecureRandom.uuid

      event_store.publish(Crm::CustomerRegistered.new(
        data: {
          customer_id: customer_id,
          name: "John Doe"
        }
      ))

      client = Customer.find_by(uid: customer_id)
      assert_not_nil(client)
      assert_equal("John Doe", client.name)
      assert_equal(customer_id, client.uid)
    end

    def test_customer_assigned_to_order
      event_store = Rails.configuration.event_store

      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      event_store.publish(Crm::CustomerRegistered.new(
        data: {
          customer_id: customer_id,
          name: "John Doe"
        }
      ))

      event_store.publish(Crm::CustomerAssignedToOrder.new(
        data: {
          customer_id: customer_id,
          order_id: order_id
        }
      ))

      order = Order.find_by(uid: order_id)
      assert_equal "Draft", order.state
    end

  end
end