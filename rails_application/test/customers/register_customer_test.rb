require "test_helper"

module Customers
  class RegisterCustomerTest < InMemoryTestCase
    cover "Customers*"

    def test_register_customer_creates_customer_with_name
      event_store.publish(customer_registered)

      customer = Customer.find(customer_id)
      assert_equal("John Doe", customer.name)
      assert_nil(customer.store_id)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def customer_id
      @customer_id ||= SecureRandom.uuid
    end

    def customer_registered
      Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "John Doe" })
    end
  end
end
