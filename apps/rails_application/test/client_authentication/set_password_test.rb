require "test_helper"

module ClientAuthentication
  class SetPasswordTest < InMemoryTestCase
    cover "ClientAuthentication::SetPassword*"

    def configure(event_store, _command_bus)
      ClientAuthentication::Configuration.new.call(event_store)
    end

    def test_sets_password_only_on_matching_account
      account_id = SecureRandom.uuid
      other_account_id = SecureRandom.uuid
      client_id = SecureRandom.uuid
      other_client_id = SecureRandom.uuid

      connect_account(account_id, client_id)
      connect_account(other_account_id, other_client_id)
      set_password(account_id, "hash-a")
      set_password(other_account_id, "hash-b")

      assert_equal("hash-a", Account.find_by(account_id: account_id).password)
      assert_equal("hash-b", Account.find_by(account_id: other_account_id).password)
    end

    def test_sets_password_before_account_is_connected
      account_id = SecureRandom.uuid
      client_id = SecureRandom.uuid

      set_password(account_id, "hash-a")
      connect_account(account_id, client_id)

      assert_equal("hash-a", Account.find_by(account_id: account_id).password)
      assert_equal(client_id, Account.find_by(account_id: account_id).client_id)
    end

    private

    def connect_account(account_id, client_id)
      event_store.publish(
        Authentication::AccountConnectedToClient.new(data: { account_id: account_id, client_id: client_id })
      )
    end

    def set_password(account_id, password_hash)
      event_store.publish(
        Authentication::PasswordHashSet.new(data: { account_id: account_id, password_hash: password_hash })
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
