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
      run_command(Ordering::AddItemToBasket.new(order_id: order_id, product_id: product_id))

      result = Orders::SubmitService.new(order_id: order_id, customer_id: customer_id).call

      assert_equal result.status, :success
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
      run_command(Ordering::AddItemToBasket.new(order_id: order_id, product_id: product_id))
      prepare_product(another_product_id, "Fearless Refactoring", 49)
      run_command(Ordering::AddItemToBasket.new(order_id: order_id, product_id: another_product_id))

      result = Orders::SubmitService.new(order_id: order_id, customer_id: customer_id).call

      assert_equal result.status, :products_out_of_stock
      assert_equal result.args, [["Async Remote"]]
    end

    def test_order_submission_with_empty_order
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      result = Orders::SubmitService.new(order_id: order_id, customer_id: customer_id).call

      assert_equal result.status, :order_is_empty
    end

    def test_order_submission_with_non_existing_customer
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      prepare_product(product_id, "Async Remote", 49)
      run_command(Ordering::AddItemToBasket.new(order_id: order_id, product_id: product_id))

      result = Orders::SubmitService.new(order_id: order_id, customer_id: customer_id).call

      assert_equal result.status, :customer_not_exists
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id, name, price)
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
    end
  end
end
