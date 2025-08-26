require "test_helper"

module Orders
  class UpdateTimePromotionDiscountValueTest < InMemoryTestCase
    cover "Orders*"

    def test_updates_time_promotion_discount_value
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      create_active_time_promotion
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      order = Orders::Order.find_by(uid: order_id)
      assert_equal 50, order.time_promotion_discount_value
      assert_nil order.percentage_discount
    end

    private

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(data: {
        product_id: product_id, order_id: order_id, price: 50, base_price: 50, base_total_value: 50, total_value: 50
      }))
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

    def create_active_time_promotion
      event_store.publish(
        Pricing::TimePromotionCreated.new(
          data: {
            time_promotion_id: SecureRandom.uuid,
            discount: 50,
            start_time: Time.current - 1,
            end_time: Time.current + 1,
            label: "Last Minute"
          }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
