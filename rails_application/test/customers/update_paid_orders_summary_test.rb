require "test_helper"

module Customers
  class UpdatePaidOrdersSummaryTest < InMemoryTestCase
    cover "Customers"

    def setup
      super
      Customer.destroy_all
    end

    def test_update_orders_summary
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      register_customer(other_customer_id)
      register_customer(customer_id)
      confirm_order(customer_id, order_id, 3)

      customer = Customer.find(customer_id)
      assert_equal 3.to_d, customer.paid_orders_summary

      order_id = SecureRandom.uuid
      confirm_order(customer_id, order_id, 6)

      customer = Customer.find(customer_id)
      assert_equal 9.to_d, customer.paid_orders_summary
    end

    private

    def register_customer(customer_id)
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
    end

    def confirm_order(customer_id, order_id, total_amount)
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      event_store.publish(
        Pricing::OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: total_amount,
            total_amount: total_amount
          }
        )
      )
      run_command(
        Crm::AssignCustomerToOrder.new(customer_id: customer_id, order_id: order_id)
      )
      run_command(Ordering::SubmitOrder.new(order_id: order_id, order_number: order_number))
      event_store.publish(
        order_confirmed = Ordering::OrderConfirmed.new(
          data: {
            order_id: order_id
          }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
