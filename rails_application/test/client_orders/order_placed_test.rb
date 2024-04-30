require "test_helper"

module ClientOrders
  class OrderPlacedTest < InMemoryTestCase
    cover "ClientOrders*"

    def setup
      super
      Client.destroy_all
      Order.destroy_all
    end

    def test_order_placed
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
        Ordering::OrderPlaced.new(
          data: {
            order_id: order_id,
            order_number: order_number,
            order_lines: { }
          }
        )
      )
      event_store.publish(
        Crm::CustomerAssignedToOrder.new(
          data: {
            order_id: order_id,
            customer_id: customer_id,
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Submitted",  orders.first.state)

      assert_clickable_order_number(customer_id, order_id, order_number)
    end

    def test_assign_customer_first
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER

      event_store.publish(
        Crm::CustomerRegistered.new(data: {customer_id: customer_id, name: "John Doe"})
      )

      event_store.publish(Crm::CustomerAssignedToOrder.new(
        data: {
          customer_id: customer_id,
          order_id: order_id
        }
      ))

      event_store.publish(
        Ordering::OrderPlaced.new(
          data: {
            order_id: order_id,
            order_number: order_number,
            order_lines: { }
          }
        )
      )
      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Submitted",  orders.first.state)
    end

    private

    def assert_clickable_order_number(customer_id, order_id, order_number)
      view_context = OrdersController.new.view_context
      orders_list = ClientOrders::OrdersList.build(view_context, customer_id)
      links_to_orders = Nokogiri::HTML(orders_list).xpath('//table').xpath(".//a")
      assert_equal(1, links_to_orders.size)
      assert_equal("/client_orders/#{order_id}", links_to_orders.first.attributes["href"].value)
      assert_equal(order_number, links_to_orders.first.text)
    end
  end
end