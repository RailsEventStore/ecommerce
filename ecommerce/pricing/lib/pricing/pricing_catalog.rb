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
      @event_store
        .read
        .of_type(PriceSet)
        .to_a
        .filter { |e| e.data.fetch(:product_id).eql?(product_id) }
        .reject(&method(:reject_future_prices))
        .last
        .data
        .fetch(:price)
    end

    private

    def reject_future_prices(e)
      e.metadata.fetch(:valid_at) > Time.now
    end
  end
end
