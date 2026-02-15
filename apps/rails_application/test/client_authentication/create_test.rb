require "test_helper"

module ClientAuthentication
  class CreateTest < InMemoryTestCase
    cover "Authentication*"

    def configure(event_store, command_bus)
      ClientAuthentication::Configuration.new.call(event_store)
    end

    def test_set_create
      customer_id = SecureRandom.uuid
      account_id = SecureRandom.uuid

      event_store.publish(
        Authentication::AccountConnectedToClient.new(
          data: {
            account_id: account_id,
            client_id: customer_id
          }
        )
      )

      customer = Account.find_by(client_id: customer_id, account_id: account_id)
      assert customer.present?
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
