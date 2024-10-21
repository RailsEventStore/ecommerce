require "test_helper"

module Orders
  class OrderPlacedTest < InMemoryTestCase
    include ActiveJob::TestHelper
    cover "Orders"

    def test_create_when_not_exists
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
          }
        )
      )
      order_placed = Ordering::OrderPlaced.new(
        data: {
          order_id: order_id,
          order_number: order_number,
          order_lines: { product_id => 1 }
        }
      )
      event_store.publish(order_placed)

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Submitted")
      assert_equal(order.number, order_number)

      assert_enqueued_with(
        job: Turbo::Streams::ActionBroadcastJob,
        args: action_broadcast_args(order_id, 'Submitted')
      )
      assert event_store.event_in_stream?(order_placed.event_id, "Orders$all")
    end

    private

    def action_broadcast_args(order_uid, state)
      [
        "orders_order_#{order_uid}",
        {
          action: :update,
          target: "orders_order_#{order_uid}_state",
          targets: nil,
          html: state
        }
      ]
    end
  end
end
