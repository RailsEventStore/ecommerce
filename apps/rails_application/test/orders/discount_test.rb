require "test_helper"

module Orders
  class DiscountTest < InMemoryTestCase
    cover "Orders*"

    def configure(event_store, _command_bus)
      Orders::Configuration.new.call(event_store)
    end

    def test_discount_set
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      set_percentage_discount(order_id)
      update_order_total_value(order_id, product_id, 50, 45)

      order = Order.find_by(uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(45, order.discounted_value)
      assert_equal(10, order.percentage_discount)
      assert_nil(order.time_promotion_discount_value)
      assert(event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountSet]).last.event_id, "Orders$all"))
    end

    def test_discount_changed
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      change_percentage_discount(order_id)
      update_order_total_value(order_id, product_id, 50, 49.5)

      order = Order.find_by(uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(49.5, order.discounted_value)
      assert_equal(1, order.percentage_discount)
      assert_nil(order.time_promotion_discount_value)
      assert(event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountChanged]).last.event_id, "Orders$all"))
    end

    def test_remove_discount
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      remove_percentage_discount(order_id)
      update_order_total_value(order_id, product_id, 50, 50)

      order = Order.find_by(uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(50, order.discounted_value)
      assert_nil(order.percentage_discount)
      assert(event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountRemoved]).last.event_id, "Orders$all"))
    end

    def test_does_not_remove_general_discount_when_removing_non_general_discount
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      event_store.publish(Pricing::PercentageDiscountRemoved.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT
        }
      ))

      order = Order.find_by(uid: order_id)
      assert_equal(10, order.percentage_discount)
    end

    def test_does_not_remove_percentage_discount_when_removing_time_promotion
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      prepare_product(product_id)
      draft_order_in_store(order_id, store_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      set_time_promotion_discount(order_id, 50)
      remove_time_promotion_discount(order_id)

      assert_equal(10, Orders.find_order_in_store(order_id, store_id).percentage_discount)
    end

    def test_newest_discount_is_always_applied
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      prepare_product(product_id)
      draft_order_in_store(order_id, store_id)
      item_added_to_basket(order_id, product_id)

      event_store.publish(Pricing::PercentageDiscountSet.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::GENERAL_DISCOUNT,
          amount: 20
        },
        metadata: {
          timestamp: 1.minute.ago
        })
      )
      assert_equal(20, Orders.find_order_in_store(order_id, store_id).percentage_discount)

      event_store.publish(Pricing::PercentageDiscountSet.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::GENERAL_DISCOUNT,
          amount: 30
        },
        metadata: {
          timestamp: Time.current
        })
      )
      assert_equal(30, Orders.find_order_in_store(order_id, store_id).percentage_discount)

      event_store.publish(Pricing::PercentageDiscountSet.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::GENERAL_DISCOUNT,
          amount: 10
        },
        metadata: {
          timestamp: 2.minutes.ago
        })
      )
      assert_equal(30, Orders.find_order_in_store(order_id, store_id).percentage_discount)
    end

    def test_newest_total_value_is_always_applied
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      prepare_product(product_id)
      draft_order_in_store(order_id, store_id)
      item_added_to_basket(order_id, product_id)

      event_store.publish(Processes::TotalOrderValueUpdated.new(
        data: {
          order_id: order_id,
          discounted_amount: 40,
          total_amount: 50,
          items: [{ product_id: product_id, quantity: 1, amount: 40 }]
        },
        metadata: {
          timestamp: 1.minute.ago
        })
      )
      assert_equal(40, Orders.find_order_in_store(order_id, store_id).discounted_value)

      event_store.publish(Processes::TotalOrderValueUpdated.new(
        data: {
          order_id: order_id,
          discounted_amount: 45,
          total_amount: 50,
          items: [{ product_id: product_id, quantity: 1, amount: 45 }]
        },
        metadata: {
          timestamp: Time.current
        })
      )
      assert_equal(45, Orders.find_order_in_store(order_id, store_id).discounted_value)

      event_store.publish(Processes::TotalOrderValueUpdated.new(
        data: {
          order_id: order_id,
          discounted_amount: 30,
          total_amount: 50,
          items: [{ product_id: product_id, quantity: 1, amount: 30 }]
        },
        metadata: {
          timestamp: 2.minutes.ago
        })
      )
      assert_equal(45, Orders.find_order_in_store(order_id, store_id).discounted_value)
    end

    private

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

    def set_time_promotion_discount(order_id, amount)
      event_store.publish(
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT,
            amount: amount
          }
        )
      )
    end

    def remove_time_promotion_discount(order_id)
      event_store.publish(
        Pricing::PercentageDiscountRemoved.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT
          }
        )
      )
    end

    def update_order_total_value(order_id, product_id, total_amount, discounted_amount)
      event_store.publish(
        Processes::TotalOrderValueUpdated.new(
          data: {
            order_id: order_id,
            discounted_amount: discounted_amount,
            total_amount: total_amount,
            items: [{ product_id: product_id, quantity: 1, amount: discounted_amount }]
          }
        )
      )
    end

    def draft_order_in_store(order_id, store_id)
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))
      event_store.publish(Stores::OfferRegistered.new(data: { order_id: order_id, store_id: store_id }))
    end

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          base_price: 50,
          price: 50,
          base_total_value: 50,
          total_value: 50
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

    def event_store
      Rails.configuration.event_store
    end
  end
end
