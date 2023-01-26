require "test_helper"

module Orders
  class OrderConfirmedTest < InMemoryTestCase
    cover "Orders*"

    def setup
      super
      Customer.destroy_all
      Order.destroy_all
    end

    def test_order_confirmed
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER

      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
      run_command(Ordering::SubmitOrder.new(order_id: order_id, order_number: order_number))
      run_command(
        Crm::AssignCustomerToOrder.new(customer_id: customer_id, order_id: order_id)
      )

      event_store.publish(Pricing::OrderTotalValueCalculated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10 }))
      order_confirmed = Ordering::OrderConfirmed.new(
        data: {
          order_id: order_id
        }
      )
      event_store.publish(order_confirmed)

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Paid", orders.first.state)
      assert event_store.event_in_stream?(order_confirmed.event_id, "Orders$all")
    end
  end
end