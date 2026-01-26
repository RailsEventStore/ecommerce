require_relative "test_helper"

module Authentication
  class RegisterAccountTest < Test
    cover "Authentication*"

    def setup
      @uid = SecureRandom.uuid
      @data = { account_id: @uid }
    end

    def test_account_should_get_registered
      account_registered = AccountRegistered.new(data: @data)
      assert_events("Authentication::Account$#{@uid}", account_registered) do
        register_account(@uid)
      end
    end

    def test_should_not_allow_for_double_registration
      assert_raises(Account::AlreadyRegistered) do
        register_account(@uid)
        register_account(@uid)
      end
    end

    private

    def register_account(account_id)
      run_command(RegisterAccount.new(account_id: account_id))
    end
  end
end
