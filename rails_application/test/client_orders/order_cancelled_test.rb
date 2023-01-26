require "test_helper"

module ClientOrders
  class OrderCancelledTest < InMemoryTestCase
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

      event_store.publish(Crm::CustomerRegistered.new(
        data: {
          customer_id: customer_id,
          name: "John Doe"
        }
      ))

      run_command(Ordering::SubmitOrder.new(order_id: order_id, order_number: order_number))

      event_store.publish(
        Ordering::OrderCancelled.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Cancelled",  orders.first.state)
    end
  end
end