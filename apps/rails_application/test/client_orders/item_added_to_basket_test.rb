require "test_helper"

module ClientOrders
  class ItemAddedToBasketTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, command_bus)
      ClientOrders::Configuration.new.call(event_store)
      Ecommerce::Configuration.new(
        number_generator: Rails.configuration.number_generator,
        payment_gateway: Rails.configuration.payment_gateway
      ).call(event_store, command_bus)
    end

    def test_add_new_item
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "test"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 49))

      order_id = SecureRandom.uuid

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 49,
            price: 49,
            base_total_value: 49,
            total_value: 49,
          }
        )
      )

      assert_equal(OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product_id)
      assert_equal(order_line.product_name, "test")
      assert_equal(order_line.product_quantity, 1)
      assert_equal(order_line.product_price, 49)
      assert_equal(order_line.value, 49)

      assert_equal(Order.count, 1)
      order = Order.find_by(order_uid: order_id)
      assert_equal(order.state, "Draft")
      assert_nil(order.client_uid)
      assert_nil(order.number)
    end

    def test_add_the_same_item_2nd_time
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "test"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 49))

      order_id = SecureRandom.uuid
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 49,
            price: 49,
            base_total_value: 49,
            total_value: 49,
          }
        )
      )

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 49,
            price: 49,
            base_total_value: 98,
            total_value: 98,
          }
        )
      )

      assert_equal(OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product_id)
      assert_equal(order_line.product_name, "test")
      assert_equal(order_line.product_quantity, 2)
      assert_equal(order_line.product_price, 49)
      assert_equal(order_line.value, 98)

      assert_equal(Order.count, 1)
      order = Order.find_by(order_uid: order_id)
      assert_equal(order.state, "Draft")
      assert_nil(order.client_uid)
      assert_nil(order.number)
    end

    def test_add_another_item
      event_store = Rails.configuration.event_store

      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
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
          product_id: another_product_id,
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: another_product_id,
          name: "2nd one"
        )
      )
      run_command(
        Pricing::SetPrice.new(product_id: another_product_id, price: 20)
      )

      order_id = SecureRandom.uuid
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 20,
            total_value: 20,
          }
        )
      )

      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: another_product_id,
            base_price: 20,
            price: 20,
            base_total_value: 40,
            total_value: 40,
          }
        )
      )

      order = ClientOrders::Order.find_by(order_uid: order_id)
      assert_equal(order.order_lines.count, 2)
      order_lines = order.order_lines
      assert_equal(
        [product_id, another_product_id],
        order_lines.map(&:product_id)
      )
      assert_equal(order_lines[0].product_id, product_id)
      assert_equal(order_lines[0].product_name, "test")
      assert_equal(order_lines[0].product_quantity, 1)

      assert_equal(order_lines[1].product_id, another_product_id)
      assert_equal(order_lines[1].product_name, "2nd one")
      assert_equal(order_lines[1].product_quantity, 1)

      assert_equal(Order.count, 1)
      order = Order.find_by(order_uid: order_id)
      assert_equal(order.state, "Draft")
      assert_nil(order.client_uid)
      assert_nil(order.number)
    end
  end
end
