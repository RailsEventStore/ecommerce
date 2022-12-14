module Products
  class Product < ApplicationRecord
    self.table_name = "products"
    serialize :future_prices_calendar, Array

    def future_prices_calendar
      super || []
    end
  end

  class Configuration
    def initialize(event_store)
      @read_model = SingleTableReadModel.new(event_store, Product, :product_id)
      @event_store = event_store
    end

    def call
      @read_model.subscribe_create(ProductCatalog::ProductRegistered)
      @read_model.copy(ProductCatalog::ProductNamed,       :name)
      @read_model.copy(Inventory::StockLevelChanged,       :stock_level)
      @read_model.copy_nested_to_column(Taxes::VatRateSet, :vat_rate, :code, :vat_rate_code)
      @event_store.subscribe(RefreshFuturePricesCalendar, to: [Pricing::FuturePriceSet])
      @event_store.subscribe(RefreshFuturePricesCalendar, to: [Pricing::PriceSet])
      @event_store.subscribe(SetPriceIfNotFuturePrice, to: [Pricing::PriceSet])
    end
  end
end
