module Products
  class Product < ApplicationRecord
    self.table_name = "products"
  end

  class Configuration

    def call(cqrs)
      cqrs.subscribe(
        -> (event) { register_product(event) },
        [ProductCatalog::ProductRegistered]
      )
      cqrs.subscribe(
        ->(event) { change_stock_level(event) },
        [Inventory::StockLevelChanged]
      )
      cqrs.subscribe(
        -> (event) { set_price(event) },
        [Pricing::PriceSet])
    end

    private

    def register_product(event)
      Product.create(id: event.data.fetch(:product_id), name: event.data.fetch(:name))
    end

    def set_price(event)
      find(event.data.fetch(:product_id)).update_attribute(:price, event.data.fetch(:price))
    end

    def change_stock_level(event)
      find(event.data.fetch(:product_id)).update_attribute(:stock_level, event.data.fetch(:stock_level))
    end

    def find(product_id)
      Product.where(id: product_id).first
    end

  end
end
