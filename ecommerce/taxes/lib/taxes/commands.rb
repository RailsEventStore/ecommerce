module Taxes
  class SetVatRate < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end

  class DetermineVatRate < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
  end
end