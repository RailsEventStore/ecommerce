require "test_helper"

module ClientOrders
  class CustomerRenamedTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_customer_renamed
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid

      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Old Name" }))
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: other_customer_id, name: "Other" }))
      event_store.publish(Crm::CustomerRenamed.new(data: { customer_id: customer_id, name: "New Name" }))

      assert_equal("New Name", Client.find_by(uid: customer_id).name)
      assert_equal("Other", Client.find_by(uid: other_customer_id).name)
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
