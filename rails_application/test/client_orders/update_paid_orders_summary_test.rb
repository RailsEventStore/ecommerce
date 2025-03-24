require "test_helper"

module ClientOrders
  class UpdatePaidOrdersSummaryTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_update_orders_summary
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      register_product(product_id)
      name_product(product_id, "Async Remote")
      set_price_to_product(product_id, 3)
      register_customer(other_customer_id)
      register_customer(customer_id)
      add_item_to_basket(order_id, product_id)
      confirm_order(customer_id, order_id, 3)

      customer = Client.find_by(uid: customer_id)
      assert_equal 3.to_d, customer.paid_orders_summary

      order_id = SecureRandom.uuid
      add_item_to_basket(order_id, product_id)
      add_item_to_basket(order_id, product_id)
      confirm_order(customer_id, order_id, 6)

      customer = Client.find_by(uid: customer_id)
      assert_equal 9.to_d, customer.paid_orders_summary
    end

    private

    def register_customer(customer_id)
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
    end

    def register_product(product_id)
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))
    end

    def name_product(product_id, name)
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: name
        )
      )
    end

    def set_price_to_product(product_id, price)
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end

    def add_item_to_basket(order_id, product_id)
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id))
    end

    def confirm_order(customer_id, order_id, total_amount)
      event_store.publish(
        Pricing::OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: total_amount,
            total_amount: total_amount
          }
        )
      )
      run_command(
        Crm::AssignCustomerToOrder.new(customer_id: customer_id, order_id: order_id)
      )
      run_command(Pricing::AcceptOffer.new(order_id: order_id))
      event_store.publish(
        order_confirmed = Fulfillment::OrderConfirmed.new(
          data: {
            order_id: order_id
          }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
