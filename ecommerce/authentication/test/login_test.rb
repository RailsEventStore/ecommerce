require_relative "test_helper"

module Authentication
  class LoginTest < Test
    cover "Authentication*"

    def test_login_with_valid_password
      password = "1234qwer"
      account_id = SecureRandom.uuid
      password_hash = Digest::SHA256.hexdigest(password)

      act(RegisterAccount.new(account_id: account_id))
      act(Authentication::SetPasswordHash.new(account_id: account_id, password_hash: password_hash))

      assert_raises(Account::WrongPassword) do
        run_command(Login.new(account_id: account_id, password: "wrong password"))
      end
    end

    def test_login_with_correct_password
      password = "1234qwer"
      account_id = SecureRandom.uuid
      password_hash = Digest::SHA256.hexdigest(password)

      act(RegisterAccount.new(account_id: account_id))
      act(Authentication::SetPasswordHash.new(account_id: account_id, password_hash: password_hash))

      assert_events("Authentication::Account$#{account_id}", LoggedIn.new(data: { account_id: account_id })) do
        run_command(Login.new(account_id: account_id, password: password))
      end
    end
  end
end
