require "test_helper"

module ClientOrders
  class DiscountTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_discount_set
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      update_order_total_value(order_id, 50, 50)

      set_percentage_discount(order_id)
      update_order_total_value(order_id, 50, 45)

      order = Order.find_by(order_uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(45, order.discounted_value)
      assert_equal(10, order.percentage_discount)
      assert_nil(order.time_promotion_discount)
    end

    def test_discount_changed
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      update_order_total_value(order_id, 50, 50)
      set_percentage_discount(order_id)

      change_percentage_discount(order_id)
      update_order_total_value(order_id, 50, 49.5)

      order = Order.find_by(order_uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(49.5, order.discounted_value)
      assert_equal(1, order.percentage_discount)
      assert_nil(order.time_promotion_discount)
    end

    def test_does_not_remove_time_promotion_when_removing_percentage_discount
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      update_order_total_value(order_id, 50, 50)
      set_time_promotion_discount(order_id, 50)
      update_order_total_value(order_id, 50, 25)
      set_percentage_discount(order_id)

      remove_percentage_discount(order_id)

      order = Order.find_by(order_uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(25, order.discounted_value)
      assert_nil(order.percentage_discount)
      assert_equal(50, order.time_promotion_discount["discount_value"])
      assert_equal("time_promotion_discount", order.time_promotion_discount["type"])
    end

    private

    def set_time_promotion_discount(order_id, amount)
      event_store.publish(Pricing::PercentageDiscountSet.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT,
          amount: amount
        }
      ))
    end

    def remove_percentage_discount(order_id)
      event_store.publish(Pricing::PercentageDiscountRemoved.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::GENERAL_DISCOUNT
        }
      ))
    end

    def set_percentage_discount(order_id)
      event_store.publish(Pricing::PercentageDiscountSet.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::GENERAL_DISCOUNT,
          amount: 10
        }
      ))
    end

    def change_percentage_discount(order_id)
      event_store.publish(Pricing::PercentageDiscountChanged.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::GENERAL_DISCOUNT,
          amount: 1
        }
      ))
    end

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          base_price: 50,
          price: 50
        }
      ))
    end

    def update_order_total_value(order_id, total_amount, discounted_amount)
      event_store.publish(Processes::TotalOrderValueUpdated.new(
        data: {
          order_id: order_id,
          total_amount: total_amount,
          discounted_amount: discounted_amount
        }
      ))
    end

    def prepare_product(product_id)
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: {
            product_id: product_id
          }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: {
            product_id: product_id,
            name: "test"
          }
        )
      )
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 50 }))
    end

    def customer_registered(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
