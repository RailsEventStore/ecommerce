require "test_helper"

module Customers
  class SetLoginTest < InMemoryTestCase
    cover "Customers::SetLogin*"

    def configure(event_store, _command_bus)
      Customers::Configuration.new.call(event_store)
    end

    def test_sets_login_only_on_customer_matching_account_id
      store_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid
      other_account_id = SecureRandom.uuid

      register_customer_in_store(customer_id, store_id)
      register_customer_in_store(other_customer_id, store_id)
      connect_account(account_id, customer_id)
      connect_account(other_account_id, other_customer_id)

      set_login(account_id, "bigcorp@example.com")

      assert_equal("bigcorp@example.com", Customers.customers_for_store(store_id).find(customer_id).login)
      assert_nil(Customers.customers_for_store(store_id).find(other_customer_id).login)
    end

    private

    def register_customer_in_store(customer_id, store_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Some Customer" }))
      event_store.publish(Stores::CustomerRegistered.new(data: { customer_id: customer_id, store_id: store_id }))
    end

    def connect_account(account_id, client_id)
      event_store.publish(Authentication::AccountConnectedToClient.new(data: { account_id: account_id, client_id: client_id }))
    end

    def set_login(account_id, login)
      event_store.publish(Authentication::LoginSet.new(data: { account_id: account_id, login: login }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
