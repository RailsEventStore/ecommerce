require "test_helper"

module Orders
  class OrderConfirmedTest < InMemoryTestCase
    cover "Orders*"

    def test_order_confirmed
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      order_number = Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      product_id = SecureRandom.uuid

      create_product(product_id, "Async Remote", 10)
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id))
      run_command(Pricing::AcceptOffer.new(order_id: order_id))
      run_command(
        Crm::AssignCustomerToOrder.new(customer_id: customer_id, order_id: order_id)
      )

      order_confirmed = Fulfillment::OrderConfirmed.new(
        data: {
          order_id: order_id
        }
      )
      event_store.publish(order_confirmed)

      orders = Order.all
      assert_not_empty(orders)
      assert_equal(1, orders.count)
      assert_equal(order_number, orders.first.number)
      assert_equal("Paid", orders.first.state)
      assert event_store.event_in_stream?(order_confirmed.event_id, "Orders$all")
    end

    private

    def create_product(product_id, name, price)
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))
      run_command(ProductCatalog::NameProduct.new(product_id: product_id, name: name))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end
  end
end
