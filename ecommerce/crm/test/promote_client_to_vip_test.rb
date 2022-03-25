require_relative "test_helper"

module Crm
  class PromoteCustomerToVipTest < Test
    cover "Crm*"

    def test_should_not_allow_for_marking_vip_as_vip_again
      customer_id = SecureRandom.uuid

      arrange(
          RegisterCustomer.new(
            customer_id: customer_id,
            name: fake_name
          )
      )

      assert_raises(Customer::AlreadyVip) do
        promote_to_vip(customer_id)
        promote_to_vip(customer_id)
      end
    end

    def test_should_publish_event
      customer_id = SecureRandom.uuid

      arrange(
          RegisterCustomer.new(
              customer_id: customer_id,
              name: fake_name
          )
      )

      customer_promoted_to_vip = CustomerPromotedToVip.new(data: {customer_id: customer_id})
      assert_events("Crm::Customer$#{customer_id}", customer_promoted_to_vip) do
        promote_to_vip(customer_id)
      end
    end

    private

    def promote_to_vip(uid)
      run_command(PromoteCustomerToVip.new(customer_id: uid))
    end
  end
end
