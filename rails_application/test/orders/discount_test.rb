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
      create_active_time_promotion
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      assert_no_changes -> { Orders::Order.find_by(uid: order_id).percentage_discount } do
        travel_to(1.minute.from_now) { item_added_to_basket(order_id, product_id) }
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
          amount: 30,
          base_total_value: 50,
          total_value: 35
        },
        metadata: {
          timestamp: Time.current
        })
      )
      event_store.publish(Pricing::PercentageDiscountSet.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::GENERAL_DISCOUNT,
          amount: 20,
          base_total_value: 50,
          total_value: 40
        },
        metadata: {
          timestamp: 1.minute.ago
        })
      )

      assert_equal 30, Orders::Order.find_by(uid: order_id).percentage_discount
    end

    private

    def remove_percentage_discount(order_id)
      run_command(Pricing::RemovePercentageDiscount.new(order_id: order_id))
    end

    def set_percentage_discount(order_id)
      run_command(Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10))
    end

    def change_percentage_discount(order_id)
      run_command(Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 1))
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
          name: "test"
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

    def create_active_time_promotion
      run_command(
        Pricing::CreateTimePromotion.new(
          time_promotion_id: SecureRandom.uuid,
          discount: 50,
          start_time: Time.current - 1,
          end_time: Time.current + 1,
          label: "Last Minute"
        )
      )
    end
  end
end
