module Taxes
  class Product
    include AggregateRoot

    VatRateNotApplicable = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def set_vat_rate(vat_rate)
      raise VatRateNotApplicable unless vat_rate_applicable?(vat_rate)
      apply(VatRateSet.new(data: { product_id: @id, vat_rate: vat_rate }))
    end

    private

    def vat_rate_applicable?(vat_rate)
      Configuration.available_vat_rates.include?(vat_rate)
    end

    on(VatRateSet) { |_| }
  end
end
