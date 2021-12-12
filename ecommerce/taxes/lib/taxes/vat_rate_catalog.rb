module Taxes
  class VatRateCatalog
    def initialize(event_store)
      @event_store = event_store
    end

    def vat_rate_for(product_id)
      @event_store
        .read
        .of_type(VatRateSet)
        .to_a
        .filter { |e| e.data.fetch(:product_id).eql?(product_id) }
        .last
        &.data
        &.fetch(:vat_rate)
    end
  end
end