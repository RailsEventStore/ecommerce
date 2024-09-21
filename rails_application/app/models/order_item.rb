class OrderItem < ApplicationRecord
  def product
    Product.unscoped.find(product_id)
  end
end
