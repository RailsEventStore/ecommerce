module Invoicing
  class InvoiceGenerated < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
  end

  class VatRateSet < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :vat_rate, Infra::Types::VatRate
  end
end