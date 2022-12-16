module Products
  class Product < ApplicationRecord
    self.table_name = "products"
    serialize :current_prices_calendar, Array

    def current_prices_calendar
      return [] unless super
      super.map(&method(:parese_calendar_entry))
    end

    def future_prices_calendar
      current_prices_calendar.select { |entry| time_of(entry) > Time.now }
    end

    def price(time = Time.now)
      price_on(time)
    end

    private

    def price_on(time)
      current_prices_calendar.each_with_index do |entry, index|
        next_entry = current_prices_calendar[index + 1]
        if time_of(entry) < time && (!next_entry || time_of(next_entry) > time)
          break entry[:price]
        end
      end
    end

    def parese_calendar_entry(entry)
      {
        valid_since: time_of(entry).to_datetime,
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
      @event_store.subscribe(RefreshFuturePricesCalendar, to: [Pricing::FuturePriceSet])
      @event_store.subscribe(RefreshFuturePricesCalendar, to: [Pricing::PriceSet])
    end
  end
end
