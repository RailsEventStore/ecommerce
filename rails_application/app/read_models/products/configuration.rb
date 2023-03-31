module Products
  class Product < ApplicationRecord
    self.table_name = "products"
    serialize :current_prices_calendar, Array

    def current_prices_calendar
      return [] unless super
      super.map(&method(:parse_calendar_entry))
    end

    def price(time = Time.current)
      last_price_before(time)
    end

    def future_prices_calendar
      current_prices_calendar.select { |entry| entry[:valid_since] > Time.current }
    end

    private

    def last_price_before(time)
      (prices_before(time).last || {})[:price]
    end

    def prices_before(time)
      current_prices_calendar.partition { |entry| entry[:valid_since] < time }.first
    end

    def parse_calendar_entry(entry)
      {
        valid_since:  Time.zone.parse(time_of(entry)).in_time_zone(Time.current.zone),
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
      @read_model.subscribe_copy(ProductCatalog::ProductNamed, :name)
      @read_model.subscribe_copy(Inventory::StockLevelChanged, :stock_level)
      @read_model.subscribe_copy(Taxes::VatRateSet, [:vat_rate, :code])
      @event_store.subscribe(RefreshFuturePricesCalendar, to: [Pricing::PriceSet])
    end
  end
end
