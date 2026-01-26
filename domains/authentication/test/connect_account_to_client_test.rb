require_relative "test_helper"

module Authentication
  class ConnectAccountToClientTest < Test
    cover "Authentication*"

    def test_client_id_should_get_set
      account_id = SecureRandom.uuid
      client_id = SecureRandom.uuid

      act(RegisterAccount.new(account_id: account_id))

      account_connected_to_client = AccountConnectedToClient.new(data: { account_id: account_id, client_id: client_id })

      assert_events("Authentication::Account$#{account_id}", account_connected_to_client) do
        run_command(ConnectAccountToClient.new(account_id: account_id, client_id: client_id))
      end
    end
  end
end
