require "test_helper"

module Customers
  class RenameCustomerTest < InMemoryTestCase
    cover "Customers::RenameCustomer*"

    def configure(event_store, _command_bus)
      Customers::Configuration.new.call(event_store)
    end

    def test_renames_only_matching_customer
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      register_customer_in_store(customer_id, "Old Name", store_id)
      register_customer_in_store(other_customer_id, "Untouched", store_id)

      event_store.publish(Crm::CustomerRenamed.new(data: { customer_id: customer_id, name: "New Name" }))

      assert_equal("New Name", Customers.customers_for_store(store_id).find(customer_id).name)
      assert_equal("Untouched", Customers.customers_for_store(store_id).find(other_customer_id).name)
    end

    private

    def register_customer_in_store(customer_id, name, store_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: name }))
      event_store.publish(Stores::CustomerRegistered.new(data: { customer_id: customer_id, store_id: store_id }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
