require "test_helper"

module ClientOrders
  class OrderDraftedTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_order_drafted
      order_id = SecureRandom.uuid

      event_store.publish(
        Pricing::OfferDrafted.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_equal(1, orders.count)
      assert_equal(order_id, orders.first.order_uid)
      assert_equal("Draft", orders.first.state)
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
