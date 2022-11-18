require "test_helper"

module ClientOrders
  class CustomerRegisteredTest < InMemoryTestCase
    cover "ClientOrders*"

    def setup
      super
      Client.destroy_all
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

      client = Client.find_by(uid: customer_id)
      assert_not_nil(client)
      assert_equal("John Doe", client.name)
      assert_equal(customer_id, client.uid)
    end

  end
end