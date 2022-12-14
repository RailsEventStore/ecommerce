module Products
  class RefreshFuturePricesCalendar < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      product = Product.find(product_id)
      product.update!(future_prices_calendar: future_prices_calendar(product_id))
    end

    private

    def future_prices_calendar(product_id)
      Pricing::PricingCatalog
        .new(event_store)
        .future_prices_catalog_by_product_id(product_id)
        .map(&method(:values_to_string))
    end

    def values_to_string(entry)
      entry.transform_values(&:to_s)
    end
  end
end
