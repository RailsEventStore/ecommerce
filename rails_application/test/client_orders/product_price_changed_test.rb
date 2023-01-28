require "test_helper"

module ClientOrders
  class ProductPriceChangedTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_reflects_change
      product_id = prepare_product
      unchanged_product_id = prepare_product

      set_price(product_id, 100)

      assert_equal 100, Product.find_by_uid(product_id).price
      assert_equal 50, Product.find_by_uid(unchanged_product_id).price
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

    def set_price(product_id, amount)
      run_command(Pricing::SetPrice.new(product_id: product_id, price: amount))
    end
  end
end
