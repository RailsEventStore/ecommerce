require_relative "test_helper"

module Crm
  class AssignCustomerToOrderTest < Test
    cover "Crm*"

    def test_customer_should_get_assigned
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      register_customer(customer_id, fake_name)
      expected_event = CustomerAssignedToOrder.new(data: {customer_id: customer_id, order_id: order_id})
      assert_events("Crm::Order$#{order_id}", expected_event) do
        assign_customer_to_order(order_id, customer_id)
      end
    end

    def test_customer_should_not_get_assigned_twice
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      register_customer(customer_id, fake_name)

      expected_event = CustomerAssignedToOrder.new(data: {customer_id: customer_id, order_id: order_id})

      assert_events("Crm::Order$#{order_id}", expected_event) do
        assign_customer_to_order(order_id, customer_id)
        assign_customer_to_order(order_id, customer_id)
      end
    end

    def test_customer_can_be_reassigned
      customer_id = SecureRandom.uuid
      another_customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      register_customer(customer_id, fake_name)
      register_customer(another_customer_id, fake_name)

      expected_event_1 = CustomerAssignedToOrder.new(data: {customer_id: customer_id, order_id: order_id})
      expected_event_2 = CustomerAssignedToOrder.new(data: {customer_id: another_customer_id, order_id: order_id})

      assert_events("Crm::Order$#{order_id}", expected_event_1, expected_event_2) do
        assign_customer_to_order(order_id, customer_id)
        assign_customer_to_order(order_id, another_customer_id)
      end
    end

    def test_customer_should_not_get_assigned_if_does_not_exist
      customer_id = SecureRandom.uuid
      another_customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      register_customer(another_customer_id, fake_name)
      assert_raises(Customer::NotExists) do
        assign_customer_to_order(order_id, customer_id)
      end
    end

    private

    def assign_customer_to_order(order_id, customer_id)
      run_command(AssignCustomerToOrder.new(order_id: order_id, customer_id: customer_id))
    end
  end
end
