module ProductCatalog
  class Registration
    def call(cmd)
      product = Product.find_or_initialize_by(id: cmd.product_id)
      product.register(cmd.name)
      product.save!
    end
  end
end
