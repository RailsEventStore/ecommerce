require "test_helper"

module Customers
  class UpdatePaidOrdersSummaryTest < InMemoryTestCase
    cover "Customers"

    def configure(event_store, command_bus)
      Customers::Configuration.new.call(event_store)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_update_orders_summary
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      register_customer(other_customer_id)
      register_customer(customer_id)
      confirm_order(customer_id, order_id, product_id, 3)

      customer = Customer.find(customer_id)
      assert_equal 3.to_d, customer.paid_orders_summary

      order_id = SecureRandom.uuid
      confirm_order(customer_id, order_id, product_id, 6)

      customer = Customer.find(customer_id)
      assert_equal 9.to_d, customer.paid_orders_summary
    end

    private

    def register_customer(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "John Doe" }))
    end

    def confirm_order(customer_id, order_id, product_id, total_amount)
      event_store.publish(
        Processes::TotalOrderValueUpdated.new(
          data: {
            order_id: order_id,
            discounted_amount: total_amount,
            total_amount: total_amount,
            items: [{ product_id: product_id, quantity: 1, amount: total_amount }]
          }
        )
      )
      event_store.publish(
        Crm::CustomerAssignedToOrder.new(
          data: { customer_id: customer_id, order_id: order_id }
        )
      )
      event_store.publish(
        Fulfillment::OrderConfirmed.new(
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
