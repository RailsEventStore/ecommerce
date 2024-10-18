module Taxes
  class VatRateSet < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end

  class VatRateDetermined < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end

  class AvailableVatRateAdded < Infra::Event
    attribute :available_vat_rate_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end

  class AvailableVatRateRemoved < Infra::Event
    attribute :vat_rate_code, Infra::Types::String
  end
end
