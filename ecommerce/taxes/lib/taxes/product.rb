module Taxes
  class Product
    include AggregateRoot

    VatRateNotApplicable = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def set_vat_rate(vat_rate, catalog)
      raise VatRateNotApplicable unless vat_rate_applicable?(vat_rate.code, catalog)
      apply(VatRateSet.new(data: { product_id: @id, vat_rate: vat_rate }))
    end

    private

    def vat_rate_applicable?(vat_rate_code, catalog)
      catalog.vat_rate_available?(vat_rate_code)
    end

    on(VatRateSet) { |_| }
  end
end
