require "test_helper"

module Customers
  class AssignStoreToCustomerTest < InMemoryTestCase
    cover "Customers*"

    def test_store_id_is_set_when_customer_registered_in_store
      event_store.publish(customer_registered)
      event_store.publish(customer_registered_in_store)

      assert_equal(store_id, Customer.find(customer_id).store_id)
    end

    def test_store_id_is_nil_when_customer_not_registered_in_store
      event_store.publish(customer_registered)

      assert_nil(Customer.find(customer_id).store_id)
    end

    def test_store_id_is_updated_when_customer_registered_in_different_store
      store_2_id = SecureRandom.uuid

      event_store.publish(customer_registered)
      event_store.publish(customer_registered_in_store)

      assert_equal(store_id, Customer.find(customer_id).store_id)

      event_store.publish(customer_registered_in_different_store(store_2_id))

      assert_equal(store_2_id, Customer.find(customer_id).store_id)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def customer_id
      @customer_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def customer_registered
      Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "John Doe" })
    end

    def customer_registered_in_store
      Stores::CustomerRegistered.new(data: { customer_id: customer_id, store_id: store_id })
    end

    def customer_registered_in_different_store(different_store_id)
      Stores::CustomerRegistered.new(data: { customer_id: customer_id, store_id: different_store_id })
    end
  end
end
