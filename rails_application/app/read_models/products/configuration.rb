module Products
  class Product < ApplicationRecord
    self.table_name = "products"
    serialize :current_prices_calendar, type: Array, coder: YAML

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

    def unavailable?
      available && available <= 0
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
        valid_since:  Time.zone.parse(time_of(entry)),
        price: BigDecimal(entry[:price])
      }
    end

    def time_of(entry)
      entry[:valid_since]
    end
  end

  private_constant :Product

  def self.products_for_store(store_id)
    Product.where(store_id: store_id)
  end

  def self.find_product(product_id)
    Product.find(product_id)
  end

  def self.product_names_for_ids(product_ids)
    Product.where(id: product_ids).pluck(:name)
  end

  def self.find_by(attributes)
    Product.find_by(attributes)
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
      @read_model.subscribe_copy(Inventory::AvailabilityChanged, :available)
      @read_model.subscribe_copy(Stores::ProductRegistered, :store_id)
      @event_store.subscribe(RefreshFuturePricesCalendar, to: [Pricing::PriceSet])
    end
  end
end
