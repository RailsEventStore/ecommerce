require "test_helper"

module Customers
  class ConnectAccountTest < InMemoryTestCase
    cover "Customers"

    def configure(event_store, command_bus)
      Customers::Configuration.new.call(event_store)
    end

    def test_first_register_then_connect
      customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid

      register_customer(customer_id)
      connect_account(account_id, customer_id)

      customer = Customer.find(customer_id)
      assert_equal account_id, customer.account_id
    end

    def test_first_connect_then_register
      customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid

      connect_account(account_id, customer_id)
      register_customer(customer_id)

      customer = Customer.find(customer_id)
      assert_equal account_id, customer.account_id
    end


    private

    def register_customer(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "John Doe" }))
    end

    def connect_account(account_id, client_id)
      event_store.publish(Authentication::AccountConnectedToClient.new(data: { account_id: account_id, client_id: client_id }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
