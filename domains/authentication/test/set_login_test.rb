require_relative "test_helper"

module Authentication
  class SetLoginTest < Test
    cover "Authentication*"

    def test_login_should_get_set
      account_id = SecureRandom.uuid

      act(RegisterAccount.new(account_id: account_id))

      login_set = LoginSet.new(data: { account_id: account_id, login: fake_login })

      assert_events("Authentication::Account$#{account_id}", login_set) do
        run_command(SetLogin.new(account_id: account_id, login: fake_login))
      end
    end
  end
end
