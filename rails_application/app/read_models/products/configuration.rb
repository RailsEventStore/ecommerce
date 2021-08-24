module Products
  class Product < ApplicationRecord
    self.table_name = "products"
  end

  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.subscribe(-> (event) { change_stock_level(event) }, [Inventory::StockLevelChanged])
    end

    private

    def change_stock_level(event)
      product = Product.find_or_create_by(id: event.data.fetch(:product_id))
      stock_level = event.data.fetch(:stock_level)
      product.stock_level = stock_level
      product.save!
    end
  end
end