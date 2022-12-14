require "test_helper"

module ClientOrders
  class DiscountTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_discount_set
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      set_percentage_discount(order_id)

      order = Order.find_by(order_uid: order_id)
      assert_equal 50, order.total_value
      assert_equal 45, order.discounted_value
      assert_equal 10, order.percentage_discount
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

      order = Order.find_by(order_uid: order_id)
      assert_equal 50, order.total_value
      assert_equal 49.5, order.discounted_value
      assert_equal 1, order.percentage_discount
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

      order = Order.find_by(order_uid: order_id)
      assert_equal(50, order.total_value)
      assert_equal(50, order.discounted_value)
      assert_nil(order.percentage_discount)
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

