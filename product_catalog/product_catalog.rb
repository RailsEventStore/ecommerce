module ProductCatalog
  class Product < ApplicationRecord
    self.table_name = "products"
  end

  class AssignPriceToProduct
    def call(event)
      product = Product.find_by(id: event.data.fetch(:product_id))
      product.price = event.data.fetch(:price)
      product.save
    end
  end
end