module ProductCatalog
  class Registration
    def initialize(product_repository, cqrs)
      @product_repository = product_repository
      @cqrs = cqrs
    end

    def call(cmd)
      product = @product_repository.find_or_initialize_by_id(cmd.product_id)
      product.register(cmd.name)
      @cqrs.publish(product_registered_event(cmd), stream_name(cmd))
      @product_repository.upsert(product)
    end

    private

    def product_registered_event(cmd)
      ProductRegistered.new(
        data: {
          product_id: cmd.product_id,
          name: cmd.name
        }
      )
    end

    def stream_name(cmd)
      "Catalog::Product$#{cmd.product_id}"
    end
  end
end
