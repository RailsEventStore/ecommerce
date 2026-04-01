require_relative "test_helper"

module Crm
  class RenameCustomerTest < Test
    cover "Crm*"

    def test_customer_can_be_renamed
      customer_id = SecureRandom.uuid
      register_customer(customer_id, "Old Name")
      expected_event = CustomerRenamed.new(data: {customer_id: customer_id, name: "New Name"})
      assert_events("Crm::Customer$#{customer_id}", expected_event) do
        rename_customer(customer_id, "New Name")
      end
    end

    private

    def rename_customer(customer_id, name)
      run_command(RenameCustomer.new(customer_id: customer_id, name: name))
    end
  end
end
