module Products
  class Product < ApplicationRecord
    self.table_name = "products"
    serialize :current_prices_calendar, Array

    def current_prices_calendar
      return [] unless super
      super.map(&method(:parese_calendar_entry))
    end

    def price(time = Time.now)
      last_price_before(time)
    end

    def future_prices_calendar
      current_prices_calendar.select { |entry| entry[:valid_since] > Time.now }
    end

    private

    def last_price_before(time)
      prices_before(time).last[:price]
    end

    def prices_before(time)
      current_prices_calendar.partition { |entry| entry[:valid_since] < time }.first
    end

    def future_prices(time)
      current_prices_catalog.find { |entry| entry[:valid_since] > time }
    end

    def parese_calendar_entry(entry)
      {
        valid_since:  Time.parse(time_of(entry)).in_time_zone(Time.now.zone),
        price: BigDecimal(entry[:price])
      }
    end

    def time_of(entry)
      entry[:valid_since]
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
      @event_store.subscribe(RefreshFuturePricesCalendar, to: [Pricing::PriceSet])
    end
  end
end
