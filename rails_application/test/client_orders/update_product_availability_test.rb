require "test_helper"

module ClientOrders
  class UpdateProductAvailabilityTest < InMemoryTestCase
     cover "ClientOrders*"

    def test_reflects_change
      product_id = prepare_product
      other_product_id = prepare_product

      supply_product(product_id, 5)

      assert_equal 5, Product.find_by_uid(product_id).available
      assert_nil Product.find_by_uid(other_product_id).available
    end

    private

    def prepare_product
      product_id = SecureRandom.uuid
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

      product_id
    end

    def supply_product(product_id, quantity)
      run_command(Inventory::Supply.new(product_id: product_id, quantity: quantity))
    end
  end
end
