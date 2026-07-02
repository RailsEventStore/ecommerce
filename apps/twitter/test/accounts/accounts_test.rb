require_relative "../test_helper"

module Accounts
  class AccountsTest < InMemoryRESTestCase
    cover "Accounts*"

    def test_handle_for_returns_the_accounts_handle
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      register(alice, "alice")
      register(bob, "bob")

      assert_equal("alice", Accounts.handle_for(alice))
      assert_equal("bob", Accounts.handle_for(bob))
    end

    def test_handle_for_returns_nil_for_unknown_account
      register(SecureRandom.uuid, "alice")

      assert_nil(Accounts.handle_for(SecureRandom.uuid))
    end

    private

    def register(account_id, handle)
      event_store.publish(::Authentication::AccountRegistered.new(data: { account_id: account_id }))
      event_store.publish(::Authentication::LoginSet.new(data: { account_id: account_id, login: handle }))
    end
  end
end
