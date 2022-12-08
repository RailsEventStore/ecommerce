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
      read_prices_set(product_id)
        .reject(&method(:reject_future_prices))
        .last
        .data
        .fetch(:price)
    end

    def future_prices_catalog_by_product_id(product)
      read_prices_set(product_id)
        .select(&method(:only_future_prices))
        .slice(:price, :valid_at)
    end

    private

    def read_prices_set(product_id)
      @event_store
        .read
        .of_type(PriceSet)
        .to_a
        .filter { |e| e.data.fetch(:product_id).eql?(product_id) }
    end

    def only_future_prices(e)
      !reject_future_prices(e)
    end

    def reject_future_prices(e)
      e.metadata.fetch(:valid_at) > Time.now
    end
  end
end
