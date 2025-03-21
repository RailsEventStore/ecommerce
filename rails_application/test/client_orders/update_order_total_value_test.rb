require "test_helper"

module ClientOrders
  class UpdateOrderTotalValueTest < InMemoryTestCase
    include ActionCable::TestHelper
    cover "ClientOrders*"

    def test_update_order_total_value_on_item_added
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      order = ClientOrders::Order.find_by(order_uid: order_id)
      assert_equal "Draft", order.state
      assert_equal 50, order.total_value
      assert_equal 50, order.discounted_value
    end

    def test_update_order_total_value_on_item_removed
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      item_removed_from_basket(order_id, product_id)

      order = ClientOrders::Order.find_by(order_uid: order_id)
      assert_equal 0, order.total_value
      assert_equal 0, order.discounted_value
    end

    def test_update_order_total_value_on_prices_recalculation
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      prices_recalculated(order_id, product_id)

      order = ClientOrders::Order.find_by(order_uid: order_id)
      assert_equal 50, order.total_value
      assert_equal 13, order.discounted_value
    end

    def test_broadcasts
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      assert_broadcast_on(
        "client_orders_#{order_id}",
        turbo_stream_action_tag(
          action: "update",
          target: "client_orders_#{order_id}_total_value",
          template: "$50.00"
        )
      )
      assert_broadcast_on(
        "client_orders_#{order_id}",
        turbo_stream_action_tag(
          action: "update",
          target: "client_orders_#{order_id}_discounted_value",
          template: "$50.00"
        )
      )
    end

    private

    def item_added_to_basket(order_id, product_id)
      publish_event(Pricing::PriceItemAdded.new(
        data: { product_id: product_id, order_id: order_id, catalog_price: 50, price: 50 }
      ))
    end

    def item_removed_from_basket(order_id, product_id)
      publish_event(Pricing::PriceItemRemoved.new(
        data: { product_id: product_id, order_id: order_id, catalog_price: 50, price: 50 }
      ))
    end

    def prices_recalculated(order_id, product_id)
      publish_event(Pricing::OfferItemsPricesRecalculated.new(
        data: { order_id: order_id, order_items: [{ product_id:, catalog_price: 50, price: 13 }] }
      ))
    end

    def prepare_product(product_id)
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
        ),
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "test"
        ),
        Pricing::SetPrice.new(product_id: product_id, price: 50)
      )
    end

    def customer_registered(customer_id)
      publish_event(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def turbo_stream_action_tag(action:, target:, template:)
      "<turbo-stream action=\"#{action}\" target=\"#{target}\"><template>#{template}</template></turbo-stream>"
    end
  end
end
