module ProductCatalog
  class AssignPriceToProduct
    def initialize(product_repository)
      @product_repository = product_repository
    end

    def call(event)
      product = @product_repository.find(event.data.fetch(:product_id))
      product.set_price(event.data.fetch(:price))
      @product_repository.upsert(product)
    end
  end
end
