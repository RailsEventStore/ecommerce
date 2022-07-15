require_relative "test_helper"

module Pricing
  class Order
    class ProductTest < Test
      cover "Pricing::Order::Product"

      def setup
        super
        @id = SecureRandom.uuid
      end

      def test_product_is_not_free_by_default
        product = Product.new(@id)
        assert_equal(false, product.free?)
      end

      def test_product_is_free_after_making_it_free
        product = Product.new(@id)
        product.make_free
        assert_equal(true, product.free?)
      end

      def test_product_is_not_free_after_removing_it_as_free
        product = Product.new(@id)
        product.make_free
        product.remove_free
        assert_equal(false, product.free?)
      end

      def test_values_equality
        refute(Product.new(@id).eql?(Product.new(SecureRandom.uuid)))
        refute(Product.new(@id).eql?(@id))
      end

      def test_hash_equality
        assert(Product.new(@id).hash.eql?(Product.hash ^ @id.hash))
        refute(Product.new(@id).hash.eql?(Product.hash ^ SecureRandom.uuid.hash))
        refute(Product.new(@id).hash == @id.hash)
      end
    end
  end
end
