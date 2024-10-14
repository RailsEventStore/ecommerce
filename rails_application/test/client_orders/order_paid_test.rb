require "test_helper"

module ClientOrders
  class OrderConfirmedTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_order_confirmed
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      product_id = SecureRandom.uuid

      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
      create_product(product_id, "Async Remote", 30)
      run_command(Ordering::AddItemToBasket.new(order_id: order_id, product_id: product_id))

      event_store.publish(
        Pricing::OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 30,
            total_amount: 30
          }
        )
      )

      run_command(Ordering::SubmitOrder.new(order_id: order_id, order_number: order_number))

      run_command(
        Crm::AssignCustomerToOrder.new(customer_id: customer_id, order_id: order_id)
      )

      event_store.publish(
        Fulfillment::OrderConfirmed.new(
          data: {
            order_id: order_id
          }
        )
      )

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Paid",  orders.first.state)
    end

    private

    def create_product(product_id, name, price)
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))
      run_command(ProductCatalog::NameProduct.new(product_id: product_id, name: name))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end
  end
end
