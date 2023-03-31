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
      assert event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountChanged]).last.event_id, "Orders$all")
    end

    def test_reset_discount
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      reset_percentage_discount(order_id)

      order = Order.find_by(uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(50, order.discounted_value)
      assert_nil(order.percentage_discount)
      assert event_store.event_in_stream?(event_store.read.of_type([Pricing::PercentageDiscountReset]).last.event_id, "Orders$all")
    end

    def test_newest_event_is_always_applied
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      event_store.publish(Pricing::PercentageDiscountSet.new(data: { order_id: order_id, amount: 30 }, metadata: { timestamp: Time.current }))
      event_store.publish(Pricing::PercentageDiscountSet.new(data: { order_id: order_id, amount: 20 }, metadata: { timestamp: 1.minute.ago }))

      assert_equal 30, Orders::Order.find_by(uid: order_id).percentage_discount
    end

    private

    def reset_percentage_discount(order_id)
      run_command(Pricing::ResetPercentageDiscount.new(order_id: order_id))
      Sidekiq::Job.drain_all
    end

    def set_percentage_discount(order_id)
      run_command(Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10))
      Sidekiq::Job.drain_all
    end

    def change_percentage_discount(order_id)
      run_command(Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 1))
      Sidekiq::Job.drain_all
    end

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Ordering::ItemAddedToBasket.new(data: { product_id: product_id, order_id: order_id, quantity_before: 0 }))
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
      Sidekiq::Job.drain_all
    end

    def customer_registered(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end

