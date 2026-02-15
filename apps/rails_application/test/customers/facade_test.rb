require "test_helper"

module Customers
  class FacadeTest < InMemoryTestCase
    cover "Customers*"

    def configure(event_store, _command_bus)
      Customers::Configuration.new.call(event_store)
    end

    def test_customers_for_store_returns_only_customers_from_given_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      customer_id_1 = SecureRandom.uuid
      customer_id_2 = SecureRandom.uuid
      customer_id_3 = SecureRandom.uuid

      register_customer_in_store(customer_id_1, "Customer 1", store_id_1)
      register_customer_in_store(customer_id_2, "Customer 2", store_id_1)
      register_customer_in_store(customer_id_3, "Customer 3", store_id_2)

      result = Customers.customers_for_store(store_id_1)

      assert_equal(2, result.count)
      assert_equal([customer_id_1, customer_id_2].sort, result.pluck(:id).sort)
    end

    def test_customers_for_store_returns_empty_when_no_customers_in_store
      store_id = SecureRandom.uuid

      result = Customers.customers_for_store(store_id)

      assert_equal(0, result.count)
    end

    def test_find_customer_in_store_returns_customer_from_given_store
      store_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      register_customer_in_store(customer_id, "Test Customer", store_id)

      result = Customers.find_customer_in_store(customer_id, store_id)

      assert_equal(customer_id, result.id)
      assert_equal("Test Customer", result.name)
    end

    def test_find_customer_in_store_raises_when_customer_not_in_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      register_customer_in_store(customer_id, "Test Customer", store_id_1)

      assert_raises(ActiveRecord::RecordNotFound) do
        Customers.find_customer_in_store(customer_id, store_id_2)
      end
    end

    def test_find_customer_in_store_raises_when_customer_not_found
      store_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      assert_raises(ActiveRecord::RecordNotFound) do
        Customers.find_customer_in_store(customer_id, store_id)
      end
    end

    private

    def register_customer_in_store(customer_id, name, store_id)
      event_store.publish(
        Crm::CustomerRegistered.new(
          data: { customer_id: customer_id, name: name }
        )
      )
      event_store.publish(
        Stores::CustomerRegistered.new(
          data: { customer_id: customer_id, store_id: store_id }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
