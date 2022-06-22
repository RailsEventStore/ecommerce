require "test_helper"

module Customers
  class CustomerPromotedToVipTest < InMemoryTestCase
    cover "Customers"

    def setup
      super
      Customer.destroy_all
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
