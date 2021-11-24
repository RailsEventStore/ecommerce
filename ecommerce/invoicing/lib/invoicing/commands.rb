module Invoicing
  class GenerateInvoice < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
  end

  class SetVatRate < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end
end