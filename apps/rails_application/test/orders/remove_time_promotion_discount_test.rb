require "test_helper"

module Orders
  class RemoveTimePromotionDiscountTest < InMemoryTestCase
    cover "Orders*"

    def configure(event_store, _command_bus)
      Orders::Configuration.new.call(event_store)
    end

    def test_removes_time_promotion_discount_value
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      other_order_id = SecureRandom.uuid

      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      item_added_to_basket(other_order_id, product_id)
      set_time_promotion_discount(order_id, 50)
      set_time_promotion_discount(other_order_id, 50)

      remove_time_promotion_discount(order_id)

      assert_nil(Orders.find_order(order_id).time_promotion_discount_value)
      assert_equal(50, Orders.find_order(other_order_id).time_promotion_discount_value)
    end

    def test_does_not_removes_time_promotion_when_removing_general_discount
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_time_promotion_discount(order_id, 50)

      assert_equal(50, Orders.find_order(order_id).time_promotion_discount_value)

      event_store.publish(
        Pricing::PercentageDiscountRemoved.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT
          }
        )
      )

      assert_equal(50, Orders.find_order(order_id).time_promotion_discount_value)
    end

    def test_removes_time_promotion_discount_when_event_published
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_time_promotion_discount(order_id, 50)

      assert_equal(50, Orders.find_order(order_id).time_promotion_discount_value)

      remove_time_promotion_discount(order_id)

      assert_nil(Orders.find_order(order_id).time_promotion_discount_value)
    end

    private

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

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(
        data: { product_id: product_id, order_id: order_id, price: 50, base_price: 50, base_total_value: 50, total_value: 50 }))
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
