require "test_helper"

module Customers
  class CustomerPromotedToVipTest < InMemoryTestCase
    cover "Customers"

    def configure(event_store, command_bus)
      Customers::Configuration.new.call(event_store)
    end

    def test_promote_customer_to_vip
      customer_id = SecureRandom.uuid
      event_store.publish(
        Crm::CustomerRegistered.new(
          data: {
            customer_id: customer_id,
            name: "Joe Fake"
          }
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

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
