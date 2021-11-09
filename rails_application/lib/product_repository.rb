class ProductRepository
  def find(product_id)
    Products::Product.where(id: product_id).first
  end

  def all
    Products::Product.all
  end
end