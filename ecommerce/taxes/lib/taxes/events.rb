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
end