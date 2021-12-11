module Taxes
  class VatRateSet < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end
end