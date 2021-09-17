module ProductCatalog
  class Registration
    def initialize(product_repository)
      @product_repository = product_repository
    end

    def call(cmd)
      product = @product_repository.find_or_initialize_by_id(cmd.product_id)
      product.register(cmd.name)
      @product_repository.upsert(product)
    end
  end
end
