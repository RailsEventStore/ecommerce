class OrderItem < ApplicationRecord
  def product
    Product.find(product_id)
  end
end
