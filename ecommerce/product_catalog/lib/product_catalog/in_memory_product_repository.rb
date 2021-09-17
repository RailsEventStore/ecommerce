module ProductCatalog
  class InMemoryProductRepository
    def initialize
      @records = {}
    end

    def upsert(product)
      @records[product.id] = product
      nil
    end

    def find(product_id)
      @records[product_id]
    end

    def find_or_initialize_by_id(id)
      find(id) || Product.new(id: id)
    end

    def all
      @records.values
    end
  end
end
