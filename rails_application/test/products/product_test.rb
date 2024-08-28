require "test_helper"

module Products
  class ProductTest < InMemoryTestCase
    cover "Products*"

    def test_unavailable
      product = Product.new(available: nil)
      refute product.unavailable?

      product = Product.new(available: 0)
      assert product.unavailable?

      product = Product.new(available: 1)
      refute product.unavailable?

      product = Product.new(available: -1)
      assert product.unavailable?
    end
  end
end
