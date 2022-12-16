require "test_helper"

module ClientOrders
  class UpdateOrderTotalValueTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_order_created_has_draft_state
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_registered(customer_id)
      prepare_product(product_id)

      event_store.publish(Pricing::OrderTotalValueCalculated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 10 }))

      order = ClientOrders::Order.find_by(order_uid: order_id)
      assert_equal "Draft", order.state
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

