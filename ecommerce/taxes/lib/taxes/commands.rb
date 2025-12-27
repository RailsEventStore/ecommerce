module Taxes
  class SetVatRate < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate_code, Infra::Types::String
  end

  class AddAvailableVatRate < Infra::Command
    attribute :available_vat_rate_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end

  class RemoveAvailableVatRate < Infra::Command
    attribute :vat_rate_code, Infra::Types::String
  end
end
