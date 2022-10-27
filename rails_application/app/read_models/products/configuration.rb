module Products
  class Product < ApplicationRecord
    self.table_name = "products"
  end

  class Configuration
    def initialize(event_store)
      @read_model = SingleTableReadModel.new(event_store, Product, :product_id)
    end

    def call
      @read_model.subscribe_create(ProductCatalog::ProductRegistered)
      @read_model.copy(ProductCatalog::ProductNamed,       :name)
      @read_model.copy(Inventory::StockLevelChanged,       :stock_level)
      @read_model.copy(Pricing::PriceSet,                  :price)
      @read_model.copy_nested_to_column(Taxes::VatRateSet, :vat_rate, :code, :vat_rate_code)
    end

  end
end
