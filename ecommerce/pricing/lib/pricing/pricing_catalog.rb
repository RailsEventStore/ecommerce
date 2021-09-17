module Pricing
  class PricingCatalog
    def initialize(event_store)
      @event_store = event_store
    end

    def price_for(product_id)
      @event_store.read.of_type(PriceSet).to_a.filter{|e| e.data.fetch(:product_id).eql?(product_id)}.last.data.fetch(:price)
    end
  end
end