module Taxes
  class SetVatRate < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate_code, Infra::Types::String
  end

  class DetermineVatRate < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
  end

  class AddAvailableVatRate < Infra::Command
    attribute :available_vat_rate_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end
end
