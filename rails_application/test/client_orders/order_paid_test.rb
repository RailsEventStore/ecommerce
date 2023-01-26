require "test_helper"

module ClientOrders
  class OrderConfirmedTest < InMemoryTestCase
    cover "ClientOrders*"

    def setup
      super
      Client.destroy_all
      Order.destroy_all
    end

    def test_order_confirmed
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER

      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))

      event_store.publish(
        Pricing::OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 30,
            total_amount: 30
          }
        )
      )

      run_command(Ordering::SubmitOrder.new(order_id: order_id, order_number: order_number))

      run_command(
        Crm::AssignCustomerToOrder.new(customer_id: customer_id, order_id: order_id)
      )

      event_store.publish(
        Ordering::OrderConfirmed.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Paid",  orders.first.state)
    end
  end
end
