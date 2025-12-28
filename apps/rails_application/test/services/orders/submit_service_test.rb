require "test_helper"

module Orders
  class SubmitServiceTest < InMemoryTestCase
    cover Orders::SubmitService

    def test_successful_order_submission
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
      prepare_product(product_id, "Async Remote", 49)
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 49))

      Orders::SubmitService.call(order_id: order_id, customer_id: customer_id)

      order = Order.find_by!(uid: order_id)

      assert_equal "Submitted", order.state
      assert_equal "John Doe", order.customer
    end

    def test_order_submission_with_unavailable_products
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid

      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "John Doe"))
      prepare_product(product_id, "Async Remote", 49)
      run_command(Inventory::Supply.new(product_id: product_id, quantity: 1))
      run_command(Inventory::Reserve.new(product_id: product_id, quantity: 1))
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: product_id, price: 49))
      prepare_product(another_product_id, "Fearless Refactoring", 49)
      run_command(Pricing::AddPriceItem.new(order_id: order_id, product_id: another_product_id, price: 49))

      error = assert_raises(Orders::OrderHasUnavailableProducts) do
        Orders::SubmitService.new(order_id: order_id, customer_id: customer_id).call
      end

      assert_equal ["Async Remote"], error.unavailable_products
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id, name, price)
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: name
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate }))
    end
  end
end
