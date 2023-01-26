require "test_helper"

module ClientOrders
  class ProductRegisteredTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_reflects_change
      product_id = SecureRandom.uuid

      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))

      assert_equal(product_id, Product.find_by_uid(product_id).uid)
    end

  end
end
