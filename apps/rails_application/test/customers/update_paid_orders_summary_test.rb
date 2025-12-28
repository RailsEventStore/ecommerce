require "test_helper"

module Customers
  class UpdatePaidOrdersSummaryTest < InMemoryTestCase
    cover "Customers"

    def setup
      super
      @order_products = Hash.new { |h, k| h[k] = [] }
    end

    def test_update_orders_summary
      customer_id = SecureRandom.uuid
      other_customer_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      register_customer(other_customer_id)
      register_customer(customer_id)
      register_product(product_id)
      name_product(product_id, "Async Remote")
      set_price_to_product(product_id, 3)
      set_vat_rate_to_product(product_id)
      add_item_to_basket(order_id, product_id, 3)
      confirm_order(customer_id, order_id, 3)

      customer = Customer.find(customer_id)
      assert_equal 3.to_d, customer.paid_orders_summary

      order_id = SecureRandom.uuid
      add_item_to_basket(order_id, product_id, 3)
      add_item_to_basket(order_id, product_id, 3)
      confirm_order(customer_id, order_id, 6)

      customer = Customer.find(customer_id)
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
      run_command(ProductCatalog::NameProduct.new(product_id: product_id, name: "Async Remote"))
    end

    def set_price_to_product(product_id, price)
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end

    def set_vat_rate_to_product(product_id)
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate }))
    end

    def add_item_to_basket(order_id, product_id, price)
      @order_products[order_id] << product_id
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: price))
    end

    def confirm_order(customer_id, order_id, total_amount)
      grouped = @order_products[order_id].group_by { |pid| pid }
      items = grouped.map do |pid, list|
        { product_id: pid, quantity: list.size, amount: total_amount }
      end
      event_store.publish(
        Processes::TotalOrderValueUpdated.new(
          data: {
            order_id: order_id,
            discounted_amount: total_amount,
            total_amount: total_amount,
            items: items
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
