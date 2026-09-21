require_relative "test_helper"

module Authentication
  class CommandsTest < Test
    cover "Authentication*"

    ACCOUNT_ID = "123e4567-e89b-42d3-a456-426614174000"
    CLIENT_ID = "223e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      connection = ConnectAccountToClient.new(ACCOUNT_ID, CLIENT_ID)

      assert_equal(ACCOUNT_ID, connection.account_id)
      assert_equal(CLIENT_ID, connection.client_id)
      assert_equal(ACCOUNT_ID, connection.aggregate_id)
      assert_equal("alice", SetLogin.new(ACCOUNT_ID, "alice").login)
      assert_equal("password hash", SetPasswordHash.new(ACCOUNT_ID, "password hash").password_hash)
    end

    def test_rejects_invalid_account_id
      account_id_constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_client_id
      assert_raises(Infra::Command::Invalid) do
        ConnectAccountToClient.new(ACCOUNT_ID, "not-a-uuid")
      end
    end

    def test_rejects_invalid_strings
      assert_raises(Infra::Command::Invalid) { SetLogin.new(ACCOUNT_ID, Object.new) }
      assert_raises(Infra::Command::Invalid) { SetPasswordHash.new(ACCOUNT_ID, Object.new) }
    end

    def test_accepts_string_subclasses
      string = Class.new(String).new("value")

      assert_equal(string, SetLogin.new(ACCOUNT_ID, string).login)
      assert_equal(string, SetPasswordHash.new(ACCOUNT_ID, string).password_hash)
    end

    private

    def account_id_constructors
      [
        ->(account_id) { RegisterAccount.new(account_id) },
        ->(account_id) { ConnectAccountToClient.new(account_id, CLIENT_ID) },
        ->(account_id) { SetLogin.new(account_id, "alice") },
        ->(account_id) { SetPasswordHash.new(account_id, "password hash") }
      ]
    end
  end
end
