require "test_helper"

module ClientAuthentication
  class SetPasswordTest < InMemoryTestCase
    cover "Authentication*"

    def configure(event_store, command_bus)
      ClientAuthentication::Configuration.new.call(event_store)
    end

    def test_set_password
      customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid
      password = "1234qwer"
      password_hash = Digest::SHA256.hexdigest(password)

      connect_to_account(customer_id, account_id)
      set_password(account_id, password_hash)

      account = Account.find_by(client_id: customer_id, account_id: account_id)
      assert_equal password_hash, account.password
    end

    def test_set_password_then_connect_account
      customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid
      password = "1234qwer"
      password_hash = Digest::SHA256.hexdigest(password)

      set_password(account_id, password_hash)
      connect_to_account(customer_id, account_id)

      account = Account.find_by(client_id: customer_id, account_id: account_id)
      assert_equal password_hash, account.password
    end

    private

    def connect_to_account(customer_id, account_id)
      event_store.publish(
        Authentication::AccountConnectedToClient.new(
          data: {
            account_id: account_id,
            client_id: customer_id
          }
        )
      )
    end

    def set_password(account_id, password_hash)
      event_store.publish(
        Authentication::PasswordHashSet.new(
          data: {
            account_id: account_id,
            password_hash: password_hash
          }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
