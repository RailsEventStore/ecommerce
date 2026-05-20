require "test_helper"

module Customers
  class UpdatePaidOrdersSummaryTest < InMemoryTestCase
    cover "Customers"

    def configure(event_store, command_bus)
      Customers::Configuration.new.call(event_store)
    end

    def test_update_orders_summary
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      register_customer(other_customer_id)
      register_customer(customer_id)

      confirm_order(customer_id, SecureRandom.uuid, product_id, 3)
      assert_equal(3.to_d, Customer.find(customer_id).paid_orders_summary)

      confirm_order(customer_id, SecureRandom.uuid, product_id, 6)
      assert_equal(9.to_d, Customer.find(customer_id).paid_orders_summary)
    end

    def test_update_orders_summary_when_customer_assigned_before_total_value
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      register_customer(customer_id)

      assign_customer_to_order(customer_id, order_id)
      update_order_total_value(order_id, product_id, 5)
      order_confirmed(order_id)

      assert_equal(5.to_d, Customer.find(customer_id).paid_orders_summary)
    end

    private

    def register_customer(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "John Doe" }))
    end

    def confirm_order(customer_id, order_id, product_id, total_amount)
      update_order_total_value(order_id, product_id, total_amount)
      assign_customer_to_order(customer_id, order_id)
      order_confirmed(order_id)
    end

    def update_order_total_value(order_id, product_id, total_amount)
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
    end

    def assign_customer_to_order(customer_id, order_id)
      event_store.publish(
        Crm::CustomerAssignedToOrder.new(
          data: { customer_id: customer_id, order_id: order_id }
        )
      )
    end

    def order_confirmed(order_id)
      event_store.publish(Fulfillment::OrderConfirmed.new(data: { order_id: order_id }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
