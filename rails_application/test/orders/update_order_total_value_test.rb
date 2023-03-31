require "test_helper"

module Orders
  class UpdateOrderTotalValueTest < InMemoryTestCase
    cover "Orders*"

    def test_order_created_has_draft_state
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)

      event_store.publish(Pricing::OrderTotalValueCalculated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10 }))

      order = Orders::Order.find_by(uid: order_id)
      assert_equal "Draft", order.state
    end

    def test_newest_event_is_always_applied
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      event_store.publish(Pricing::OrderTotalValueCalculated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10 }, metadata: { timestamp: Time.current }))
      event_store.publish(Pricing::OrderTotalValueCalculated.new(data: { order_id: order_id, amount: 20, discounted_amount: 10, total_amount: 20 }, metadata: { timestamp: 1.minute.ago }))

      order = Orders::Order.find_by(uid: order_id)
      assert_equal 10, order.total_value
      assert_equal 0, order.discounted_value
    end

    private

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
