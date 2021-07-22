require 'test_helper'

module Orders
  class ItemRemovedFromBasketTest < Ecommerce::InMemoryTestCase

    cover 'Orders'

    test 'remove item when quantity > 1' do
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "something"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      event_store.publish(Pricing::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product_id}))
      event_store.publish(Pricing::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product_id}))
      event_store.publish(Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer_id}))

      event_store.publish(Pricing::ItemRemovedFromBasket.new(data: {order_id: order_id, product_id: product_id}))

      assert_equal(OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product_id)
      assert_equal(order_line.product_name, 'something')
      assert_equal(order_line.quantity , 1)
    end

    test 'remove item when quantity = 1' do
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      event_store.publish(Pricing::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product_id}))
      event_store.publish(Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer_id}))

      event_store.publish(Pricing::ItemRemovedFromBasket.new(data: {order_id: order_id, product_id: product_id}))

      assert_equal(OrderLine.count, 0)
    end

    test 'remove item when there is another item' do
      event_store = Rails.configuration.event_store


      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))


      another_product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: another_product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: another_product_id, price: 20))
      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'dummy'))
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      event_store.publish(Pricing::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product_id}))
      event_store.publish(Pricing::ItemAddedToBasket.new(data: {order_id: order_id, product_id: product_id}))
      event_store.publish(Pricing::ItemAddedToBasket.new(data: {order_id: order_id, product_id: another_product_id}))
      event_store.publish(Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer_id}))

      event_store.publish(Pricing::ItemRemovedFromBasket.new(data: {order_id: order_id, product_id: another_product_id}))

      assert_equal(OrderLine.count, 1)
      order_lines = OrderLine.where(order_uid: order_id)
      assert_equal(order_lines[0].product_id, product_id)
      assert_equal(order_lines[0].product_name, 'test')
      assert_equal(order_lines[0].quantity , 2)
    end
  end
end
