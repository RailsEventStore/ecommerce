require "test_helper"

module ClientOrders
  class OrderConfirmedTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, command_bus)
      ClientOrders::Configuration.new.call(event_store)
      Ecommerce::Configuration.new(
        number_generator: Rails.configuration.number_generator,
        payment_gateway: Rails.configuration.payment_gateway
      ).call(event_store, command_bus)
    end

    def test_order_confirmed
      event_store = Rails.configuration.event_store
      customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
      create_product(product_id, "Async Remote", 30)
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 30))

      event_store.publish(
        Processes::TotalOrderValueUpdated.new(
          data: {
            order_id: order_id,
            discounted_amount: 30,
            total_amount: 30,
            items: [ { product_id: product_id, quantity: 1, amount: 30 } ]
          }
        )
      )

      run_command(Pricing::AcceptOffer.new(order_id: order_id))

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
      assert_equal("Paid",  orders.first.state)
    end

    private

    def create_product(product_id, name, price)
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))
      run_command(ProductCatalog::NameProduct.new(product_id: product_id, name: name))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
      Rails.configuration.event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate }))
    end
  end
end
