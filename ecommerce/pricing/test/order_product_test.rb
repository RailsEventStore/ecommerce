require_relative "test_helper"

module Pricing
  class Order
    class ProductTest < Test
      cover "Pricing::Order::Product"

      def setup
        super
        @id = SecureRandom.uuid
      end

      def test_values_equality
        refute(Product.new(@id).eql?(FreeProduct.new(@id)))
        refute(Product.new(@id).eql?(Product.new(SecureRandom.uuid)))
        refute(Product.new(@id).eql?(@id))
      end

      def test_hash_equality
        assert(Product.new(@id).hash.eql?(Product.hash ^ @id.hash))
        refute(Product.new(@id).hash.eql?(Product.hash ^ SecureRandom.uuid.hash))
        refute(Product.new(@id).hash == @id.hash)
      end
    end

    class FreeProductTest < Test
      cover "Pricing::Order::FreeProduct"

      def setup
        super
        @id = SecureRandom.uuid
      end

      def test_values_equality
        refute(FreeProduct.new(@id).eql?(Product.new(@id)))
        refute(FreeProduct.new(@id).eql?(FreeProduct.new(SecureRandom.uuid)))
        refute(FreeProduct.new(@id).eql?(@id))
      end

      def test_hash_equality
        assert(FreeProduct.new(@id).hash.eql?(FreeProduct.hash ^ @id.hash))
        refute(FreeProduct.new(@id).hash.eql?(FreeProduct.hash ^ SecureRandom.uuid.hash))
        refute(FreeProduct.new(@id).hash == @id.hash)
      end
    end
  end
end
