require "test_helper"

module Orders
  class OrderSubmittedTest < InMemoryTestCase
    include ActiveJob::TestHelper
    cover "Orders"

    def setup
      super
      Order.destroy_all
      OrderLine.destroy_all
    end

    def test_create_when_not_exists
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER

      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )
      order_submitted = Ordering::OrderSubmitted.new(
        data: {
          order_id: order_id,
          order_number: order_number,
          order_lines: { product_id => 1 }
        }
      )
      event_store.publish(order_submitted)

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Submitted")
      assert_equal(order.number, order_number)

      assert_enqueued_with(
        job: Turbo::Streams::ActionBroadcastJob,
        args: action_broadcast_args(order_id, 'Submitted')
      )
      assert event_store.event_in_stream?(order_submitted.event_id, "Orders$all")
    end

    def test_skip_when_duplicated
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 0
          }
        )
      )
      event_store.publish(
        Ordering::OrderSubmitted.new(
          data: {
            order_id: order_id,
            order_number: order_number,
            order_lines: { product_id => 1 }
          }
        )
      )

      event_store.publish(
        Ordering::OrderSubmitted.new(
          data: {
            order_id: order_id,
            order_number: order_number,
            order_lines: { product_id => 1 }
          }
        )
      )

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Submitted")
      assert_equal(order.number, order_number)
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
