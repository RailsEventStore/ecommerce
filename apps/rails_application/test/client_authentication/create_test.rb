require "test_helper"

module ClientAuthentication
  class CreateTest < InMemoryTestCase
    cover "Authentication*"

    def configure(event_store, command_bus)
      ClientAuthentication::Configuration.new.call(event_store)
      Ecommerce::Configuration.new(
        number_generator: Rails.configuration.number_generator,
        payment_gateway: Rails.configuration.payment_gateway
      ).call(event_store, command_bus)
    end

    def test_set_create
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      account_id = SecureRandom.uuid
      password = "1234qwer"
      password_hash = Digest::SHA256.hexdigest(password)

      register_customer(customer_id)

      run_command(
        Authentication::ConnectAccountToClient.new(
          account_id: account_id,
          client_id: customer_id
        )
      )

      customer = Account.find_by(client_id: customer_id, account_id: account_id)
      assert customer.present?
    end

    private

    def register_customer(customer_id)
      run_command(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe")
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
