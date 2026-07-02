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

    def test_authenticate_returns_account_id_for_correct_password
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      register(alice, "alice", "s3cret")
      register(bob, "bob", "hunter2")

      assert_equal(alice, Accounts.authenticate("alice", "s3cret"))
      assert_equal(bob, Accounts.authenticate("bob", "hunter2"))
    end

    def test_authenticate_returns_nil_for_wrong_password
      register(SecureRandom.uuid, "alice", "s3cret")

      assert_nil(Accounts.authenticate("alice", "wrong"))
    end

    def test_authenticate_returns_nil_for_unknown_handle
      register(SecureRandom.uuid, "alice", "s3cret")

      assert_nil(Accounts.authenticate("bob", "s3cret"))
    end

    private

    def register(account_id, handle, password = "password")
      event_store.publish(::Authentication::AccountRegistered.new(data: { account_id: account_id }))
      event_store.publish(::Authentication::LoginSet.new(data: { account_id: account_id, login: handle }))
      event_store.publish(
        ::Authentication::PasswordHashSet.new(
          data: { account_id: account_id, password_hash: BCrypt::Password.create(password) }
        )
      )
    end
  end
end
