require "test_helper"

module ClientOrders
  class OrderExpiredTest < InMemoryTestCase
    cover "ClientOrders*"

    def setup
      super
      Client.destroy_all
      Order.destroy_all
    end

    def test_order_expired
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

      event_store.publish(
        Ordering::OrderSubmitted.new(
          data: {
            order_id: order_id,
            order_number: order_number,
            customer_id: customer_id,
            order_lines: { }
          }
        )
      )

      event_store.publish(
        Ordering::OrderExpired.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Expired",  orders.first.state)
    end
  end
end