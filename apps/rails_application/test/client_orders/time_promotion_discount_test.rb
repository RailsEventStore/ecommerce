require "test_helper"

module ClientOrders
  class TimePromotionDiscountTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_time_promotion_set
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      travel_to(Time.utc(2015, 1, 1, 12, 0, 0)) do
        register_store(store_id)
        customer_registered(customer_id)
        prepare_product(product_id)
        create_active_time_promotion(50, store_id)
        register_offer(order_id, store_id)
        item_added_to_basket(order_id, product_id)

        order = ClientOrders::Order.find_by(order_uid: order_id)
        assert_equal 50, order.total_value
        assert_equal 25, order.discounted_value
        assert_equal 50, order.time_promotion_discount["discount_value"]
        assert_equal "time_promotion_discount", order.time_promotion_discount["type"]
        assert_nil order.percentage_discount
      end
    end

    def test_does_not_remove_percentage_discount_when_removing_time_promotion
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      base_time = Time.utc(2014, 1, 1, 12, 0, 0)
      travel_to(base_time) do
        register_store(store_id)
        customer_registered(customer_id)
        prepare_product(product_id)
        create_active_time_promotion(50, store_id)
        register_offer(order_id, store_id)
        set_percentage_discount(order_id)
      end

      travel_to(base_time + 2.days) do
        item_added_to_basket(order_id, product_id)
      end

      order = ClientOrders::Order.find_by(order_uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(45, order.discounted_value)
      assert_equal(10, order.percentage_discount)
      assert_nil(order.time_promotion_discount)
    end

    private

    def create_active_time_promotion(discount, store_id)
      time_promotion_id = SecureRandom.uuid
      run_command(
        Pricing::CreateTimePromotion.new(
          time_promotion_id: time_promotion_id,
          discount: discount,
          start_time: Time.current - 1,
          end_time: Time.current + 1,
          label: "Last Minute"
        )
      )
      run_command(
        Stores::RegisterTimePromotion.new(
          time_promotion_id: time_promotion_id,
          store_id: store_id
        )
      )
    end

    def set_percentage_discount(order_id)
      run_command(Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10))
    end

    def item_added_to_basket(order_id, product_id)
      run_command(Pricing::AddPriceItem.new(product_id: product_id, order_id: order_id, price: 50))
    end

    def prepare_product(product_id)
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 50))
    end

    def customer_registered(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def event_store
      Rails.configuration.event_store
    end

    def register_store(store_id)
      run_command(Stores::RegisterStore.new(store_id: store_id))
    end

    def register_offer(order_id, store_id)
      run_command(Pricing::DraftOffer.new(order_id: order_id))
      run_command(Stores::RegisterOffer.new(order_id: order_id, store_id: store_id))
    end
  end
end
