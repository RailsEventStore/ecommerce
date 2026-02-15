require "test_helper"

module Customers
  class CustomerPromotedToVipTest < InMemoryTestCase
    cover "Customers"

    def configure(event_store, command_bus)
      Customers::Configuration.new.call(event_store)
      Ecommerce::Configuration.new(
        number_generator: Rails.configuration.number_generator,
        payment_gateway: Rails.configuration.payment_gateway
      ).call(event_store, command_bus)
    end

    def test_promote_customer_to_vip
      event_store = Rails.configuration.event_store

      customer_id = SecureRandom.uuid
      run_command(
          Crm::RegisterCustomer.new(
            customer_id: customer_id,
            name: "Joe Fake"
          )
      )

      event_store.publish(
          Crm::CustomerPromotedToVip.new(
              data: {
                  customer_id: customer_id
              }
          )
      )

      customer = Customer.find_by(id: customer_id)
      assert_equal(customer.vip, true)
    end
  end
end
