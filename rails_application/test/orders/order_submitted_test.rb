require 'test_helper'

module Orders
  class OrderSubmittedTest < Ecommerce::InMemoryTestCase

    cover 'Orders'

    def setup
      super
      Order.destroy_all
      OrderLine.destroy_all
    end

    def test_create_when_not_exists
      event_store = Rails.configuration.event_store

      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))

      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER

      event_store.publish(Pricing::ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_id }))
      event_store.publish(Ordering::OrderSubmitted.new(data: { order_id: order_id, order_number: order_number, customer_id: customer_id }))

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, 'Submitted')
      assert_equal(order.number, order_number)
      assert_equal(order.customer, 'dummy')
    end

    def test_skip_when_duplicated
      event_store = Rails.configuration.event_store

      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))

      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      event_store.publish(Pricing::ItemAddedToBasket.new(data: { order_id: order_id, product_id: product_id }))
      event_store.publish(Ordering::OrderSubmitted.new(data: { order_id: order_id, order_number: order_number, customer_id: customer_id }))

      assert_raises(Inventory::Reservation::AlreadySubmitted) do
        event_store.publish(Ordering::OrderSubmitted.new(data: { order_id: order_id, order_number: order_number, customer_id: customer_id }))
      end

      assert_equal(Order.count, 1)
      order = Order.find_by(uid: order_id)
      assert_equal(order.state, 'Submitted')
      assert_equal(order.number, order_number)
      assert_equal(order.customer, 'dummy')
    end
  end
end
