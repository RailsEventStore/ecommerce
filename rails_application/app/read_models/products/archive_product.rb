module Products
  class ArchiveProduct
    def call(event)
      product = Product.find_by(id: event.data[:product_id])
      product&.update!(archived: true)
    end
  end
end