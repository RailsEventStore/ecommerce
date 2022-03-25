require "test_helper"

module Orders
  class OrderSubmittedTest < InMemoryTestCase
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
          product_id: product_id,
          name: "test"
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

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Submitted")
      assert_equal(order.number, order_number)
    end

    def test_skip_when_duplicated
      event_store = Rails.configuration.event_store

      # customer_id = SecureRandom.uuid
      # run_command(
      #   Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      # )

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          name: "test"
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

      assert_raises(Inventory::Reservation::AlreadySubmitted) do
        event_store.publish(
          Ordering::OrderSubmitted.new(
            data: {
              order_id: order_id,
              order_number: order_number,
              order_lines: { product_id => 1 }
            }
          )
        )
      end

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, "Submitted")
      assert_equal(order.number, order_number)
    end
  end
end
