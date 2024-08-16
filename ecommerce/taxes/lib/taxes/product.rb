module Taxes
  class Product
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def set_vat_rate(vat_rate)
      apply(VatRateSet.new(data: { product_id: @id, vat_rate: vat_rate }))
    end

    private

    on(VatRateSet) { |_| }
  end
end
