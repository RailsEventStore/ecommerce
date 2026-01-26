require_relative "test_helper"

module Authentication
  class SetPasswordHashTest < Test
    cover "Authentication*"

    def test_password_hash_should_get_set
      account_id = SecureRandom.uuid
      password_hash = SecureRandom.hex(10)

      act(RegisterAccount.new(account_id: account_id))

      password_hash_set = PasswordHashSet.new(data: { account_id: account_id, password_hash: password_hash })

      assert_events("Authentication::Account$#{account_id}", password_hash_set) do
        run_command(SetPasswordHash.new(account_id: account_id, password_hash: password_hash))
      end
    end
  end
end
