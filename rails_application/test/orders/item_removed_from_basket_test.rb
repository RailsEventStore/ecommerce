require "test_helper"

module Orders
  class ItemRemovedFromBasketTest < InMemoryTestCase
    cover "Orders"

    def setup
      super
      Order.destroy_all
      OrderLine.destroy_all
      Product.destroy_all
    end

    def test_remove_item_when_quantity_gt_1
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
          name: "something"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      customer_id = SecureRandom.uuid
      run_command(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      )
      order_id = SecureRandom.uuid
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
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 1
          }
        )
      )
      event_store.publish(
        Ordering::ItemRemovedFromBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      )

      assert_equal(OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product_id)
      assert_equal(order_line.product_name, "something")
      assert_equal(order_line.quantity, 1)
    end

    def test_remove_item_when_quantity_eq_1
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      customer_id = SecureRandom.uuid
      run_command(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      )
      order_id = SecureRandom.uuid
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
        Ordering::ItemRemovedFromBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      )

      assert_equal(OrderLine.count, 0)
    end

    def test_remove_item_when_there_is_another_item
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
          name: "test"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      another_product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: another_product_id
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: another_product_id,
          name: "test2"
        )
      )
      run_command(
        Pricing::SetPrice.new(product_id: another_product_id, price: 20)
      )
      customer_id = SecureRandom.uuid
      run_command(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      )
      order_id = SecureRandom.uuid
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
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: 1
          }
        )
      )
      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: another_product_id,
            quantity_before: 0
          }
        )
      )
      event_store.publish(
        Ordering::ItemRemovedFromBasket.new(
          data: {
            order_id: order_id,
            product_id: another_product_id
          }
        )
      )

      assert_equal(OrderLine.count, 1)
      order_lines = OrderLine.where(order_uid: order_id)
      assert_equal(order_lines[0].product_id, product_id)
      assert_equal(order_lines[0].product_name, "test")
      assert_equal(order_lines[0].quantity, 2)
    end
  end
end
