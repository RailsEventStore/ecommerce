module Pricing
  class PricingCatalog
    def initialize(event_store)
      @event_store = event_store
    end

    def price_for(product)
      case product
      when Order::FreeProduct
        0
      else
        price_by_product_id(product.id)
      end
    end

    def price_by_product_id(product_id)
      current_price(product_id)
        .data
        .fetch(:price)
    end

    def current_prices_catalog_by_product_id(product_id)
      [to_calendar_entry(current_price(product_id))] + future_prices_catalog_by_product_id(product_id)
    end

    def future_prices_catalog_by_product_id(product_id)
      read_prices_set(product_id)
        .select(&method(:future_prices))
        .map(&method(:to_calendar_entry))
        .sort_by { |entry| entry.fetch(:valid_since) }
    end

    private

    def current_price(product_id)
      read_prices_set(product_id)
        .reject(&method(:future_prices))
        .last
    end

    def read_prices_set(product_id)
      @event_store
        .read
        .of_type(PriceSet)
        .to_a
        .filter { |e| e.data.fetch(:product_id).eql?(product_id) }
    end

    def future_prices(e)
      e.metadata.fetch(:valid_at) > Time.now
    end

    def to_calendar_entry(e)
      {
        price: e.data.fetch(:price),
        valid_since: e.metadata.fetch(:valid_at)
      }
    end
  end
end
