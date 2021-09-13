module ProductCatalog
  class AssignPriceToProduct
    def call(event)
      product = Product.find_by(id: event.data.fetch(:product_id))
      product.price = event.data.fetch(:price)
      product.save!
    end
  end
end