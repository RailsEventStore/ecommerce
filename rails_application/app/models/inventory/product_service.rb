# frozen_string_literal: true

module Inventory
  class ProductService

    def decrement_stock_level(product_id)
      product = ::Product.find(product_id)
      product.decrement!(:stock_level)
    end

    def increment_stock_level(product_id)
      product = ::Product.find(product_id)
      product.increment!(:stock_level)
    end

    def supply(product_id, quantity)
      product = ::Product.find(product_id)
      product.stock_level == nil ? product.stock_level = quantity : product.stock_level += quantity
      product.save!
    end
  end
end
