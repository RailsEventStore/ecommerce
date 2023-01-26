require "test_helper"

module Orders
  class OrderCancelledTest < InMemoryTestCase
    cover "Orders*"

    def setup
      super
      Customer.destroy_all
      Order.destroy_all
    end

    def test_cancel_confirmed_order
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

      order_cancelled = Ordering::OrderCancelled.new(
        data: {
          order_id: order_id
        }
      )
      event_store.publish(order_cancelled)


      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Cancelled", orders.first.state)
      assert event_store.event_in_stream?(order_cancelled.event_id, "Orders$all")
    end
  end
end