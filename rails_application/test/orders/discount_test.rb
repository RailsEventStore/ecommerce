require "test_helper"

module Orders
  class DiscountTest < InMemoryTestCase
    cover "Orders*"

    def test_discount_set
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      set_percentage_discount(order_id)

      order = Order.find_by(uid: order_id)
      assert_equal 50, order.total_value
      assert_equal 45, order.discounted_value
      assert_equal 10, order.percentage_discount
      assert_nil order.time_promotion_discount_value
      assert event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountSet]).last.event_id, "Orders$all")
    end

    def test_discount_changed
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      change_percentage_discount(order_id)

      order = Order.find_by(uid: order_id)
      assert_equal 50, order.total_value
      assert_equal 49.5, order.discounted_value
      assert_equal 1, order.percentage_discount
      assert_nil order.time_promotion_discount_value
      assert event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountChanged]).last.event_id, "Orders$all")
    end

    def test_remove_discount
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      remove_percentage_discount(order_id)

      order = Order.find_by(uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(50, order.discounted_value)
      assert_nil(order.percentage_discount)
      assert event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountRemoved]).last.event_id, "Orders$all")
    end

    def test_does_not_remove_percentage_discount_when_removing_time_promotion
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      base_time = Time.utc(2020, 1, 1, 12, 0, 0)
      travel_to(base_time) do
        event_store.publish(
          Pricing::TimePromotionCreated.new(
            data: {
              time_promotion_id: SecureRandom.uuid,
              discount: 50,
              start_time: base_time - 1.second,
              end_time: base_time + 1.minute,
              label: "Last Minute"
            }
          )
        )
        customer_registered(customer_id)
        prepare_product(product_id)
        item_added_to_basket(order_id, product_id)
        set_percentage_discount(order_id)
      end

      travel_to(base_time + 2.minutes) do
        assert_no_changes -> { Orders::Order.find_by(uid: order_id).percentage_discount } do
          item_added_to_basket(order_id, product_id)
        end
      end
    end

    def test_newest_event_is_always_applied
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

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

      assert_equal 30, Orders::Order.find_by(uid: order_id).percentage_discount
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

    def customer_registered(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
