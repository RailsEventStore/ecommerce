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

    def vat_rate_by_code(vat_rate_code)
      @event_store
        .read
        .stream("Taxes::AvailableVatRate$#{vat_rate_code}")
        .last
        &.data
        &.fetch(:vat_rate)
        &.then { |vat_rate| Infra::Types::VatRate.new(vat_rate) }
    end
  end
end
