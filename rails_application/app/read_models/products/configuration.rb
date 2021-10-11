module Products
  class Product < ApplicationRecord
    self.table_name = "products"
  end

  class Configuration
    def initialize(product_repository)
      @product_repository = product_repository
    end

    def call(cqrs)
      cqrs.subscribe(
        ->(event) { change_stock_level(event) },
        [Inventory::StockLevelChanged]
      )
    end

    private

    def change_stock_level(event)
      product =
        @product_repository.find_or_initialize_by_id(
          event.data.fetch(:product_id)
        )
      product.set_stock_level(event.data.fetch(:stock_level))
      @product_repository.upsert(product)
    end
  end
end
