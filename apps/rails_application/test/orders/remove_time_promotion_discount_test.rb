require "test_helper"

module Orders
  class RemoveTimePromotionDiscountTest < InMemoryTestCase
    cover "Orders*"

    def configure(event_store, command_bus)
      Orders::Configuration.new.call(event_store)
      Ecommerce::Configuration.new(
        number_generator: Rails.configuration.number_generator,
        payment_gateway: Rails.configuration.payment_gateway
      ).call(event_store, command_bus)
      Processes::Configuration.new.call(event_store, command_bus)
    end

    def test_removes_time_promotion_discount_value
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      base_time = Time.utc(2018, 1, 1, 12, 0, 0)
      travel_to(base_time) do
        create_active_time_promotion
        customer_registered(customer_id)
        prepare_product(product_id)
        item_added_to_basket(order_id, product_id)
      end

      travel_to(base_time + 2.minutes) do
        item_added_to_basket(order_id, product_id)
        order = Orders.find_order( order_id)
        assert_nil order.time_promotion_discount_value
      end
    end

    def test_does_not_removes_time_promotion_when_removing_general_discount
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      travel_to(Time.utc(2017, 1, 1, 12, 0, 0)) do
        create_active_time_promotion(store_id)
        customer_registered(customer_id)
        prepare_product(product_id)
        register_offer(order_id, store_id)
        item_added_to_basket(order_id, product_id)

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
    end

    def test_removes_time_promotion_discount_when_event_published
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      travel_to(Time.utc(2019, 1, 1, 12, 0, 0)) do
        create_active_time_promotion(store_id)
        customer_registered(customer_id)
        prepare_product(product_id)
        register_offer(order_id, store_id)
        item_added_to_basket(order_id, product_id)

        assert_equal(50, Orders.find_order(order_id).time_promotion_discount_value)

        event_store.publish(
          Pricing::PercentageDiscountRemoved.new(
            data: {
              order_id: order_id,
              type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT
            }
          )
        )

        assert_nil(Orders.find_order(order_id).time_promotion_discount_value)
      end
    end

    private

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

    def customer_registered(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def create_active_time_promotion(store_id = nil)
      time_promotion_id = SecureRandom.uuid
      event_store.publish(
        Pricing::TimePromotionCreated.new(
          data: {
            time_promotion_id: time_promotion_id,
            discount: 50,
            start_time: Time.current - 1,
            end_time: Time.current + 1,
            label: "Last Minute"
          }
        ),
        stream_name: "Pricing::TimePromotion$#{time_promotion_id}"
      )
      if store_id
        event_store.publish(
          Stores::TimePromotionRegistered.new(
            data: {
              time_promotion_id: time_promotion_id,
              store_id: store_id
            }
          ),
          stream_name: "Stores::Store$#{store_id}"
        )
      end
    end

    def register_offer(order_id, store_id)
      event_store.publish(
        Pricing::OfferDrafted.new(
          data: {
            order_id: order_id
          }
        )
      )
      event_store.publish(
        Stores::OfferRegistered.new(
          data: {
            order_id: order_id,
            store_id: store_id
          }
        ),
        stream_name: "Stores::Store$#{store_id}"
      )
    end

    def event_store
      Rails.configuration.event_store
    end

    def set_percentage_discount(order_id)
      event_store.publish(
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 10
          }
        )
      )
    end

    def remove_percentage_discount(order_id)
      event_store.publish(
        Pricing::PercentageDiscountRemoved.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT
          }
        )
      )
    end
  end
end
