event_store = Rails.configuration.event_store
pricing_catalog = Pricing::PricingCatalog.new(event_store)
Products::Product.all.each do |product|
  calendar = pricing_catalog.current_prices_catalog_by_product_id(product.id)
    .map { |entry| entry.transform_values(&:to_s) }
  product.update(current_prices_calendar: calendar)
end

