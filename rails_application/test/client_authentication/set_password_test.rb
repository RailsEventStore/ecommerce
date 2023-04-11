require "test_helper"

module ClientAuthentication
  class SetPasswordTest < InMemoryTestCase
    cover "Authentication*"

    def setup
      super
      Account.destroy_all
    end

    def test_set_password
      customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid
      password = "1234qwer"
      password_hash = Digest::SHA256.hexdigest(password)

      register_customer(customer_id)
      connect_to_account(customer_id, account_id)

      run_command(
        Authentication::SetPasswordHash.new(account_id: account_id, password_hash: password_hash)
      )
      Sidekiq::Job.drain_all

      account = Account.find_by(client_id: customer_id, account_id: account_id)
      assert_equal password_hash, account.password
    end

    def test_set_password_then_connect_account
      customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid
      password = "1234qwer"
      password_hash = Digest::SHA256.hexdigest(password)

      register_customer(customer_id)
      Sidekiq::Job.drain_all
      run_command(
        Authentication::SetPasswordHash.new(account_id: account_id, password_hash: password_hash)
      )
      Sidekiq::Job.drain_all
      connect_to_account(customer_id, account_id)

      Sidekiq::Job.drain_all

      account = Account.find_by(client_id: customer_id, account_id: account_id)
      assert_equal password_hash, account.password
    end

    private

    def register_customer(customer_id)
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
    end

    def connect_to_account(customer_id, account_id)
      run_command(
        Authentication::ConnectAccountToClient.new(account_id: account_id, client_id: customer_id)
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
