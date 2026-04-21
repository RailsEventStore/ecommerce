require "test_helper"

module ClientAuthentication
  class CreateTest < InMemoryTestCase
    cover "ClientAuthentication::CreateAccount*"

    def configure(event_store, _command_bus)
      ClientAuthentication::Configuration.new.call(event_store)
    end

    def test_connects_client_to_matching_account_only
      account_id = SecureRandom.uuid
      other_account_id = SecureRandom.uuid
      client_id = SecureRandom.uuid
      other_client_id = SecureRandom.uuid

      connect_account(account_id, client_id)
      connect_account(other_account_id, other_client_id)

      assert_equal(client_id, Account.find_by(account_id: account_id).client_id)
      assert_equal(other_client_id, Account.find_by(account_id: other_account_id).client_id)
    end

    private

    def connect_account(account_id, client_id)
      event_store.publish(
        Authentication::AccountConnectedToClient.new(data: { account_id: account_id, client_id: client_id })
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
