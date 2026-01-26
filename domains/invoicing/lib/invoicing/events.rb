module Invoicing
  class InvoiceItemAdded < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :title, Infra::Types::String
    attribute :quantity, Infra::Types::Quantity
    attribute :unit_price, Infra::Types::Price
    attribute :vat_rate, Infra::Types::VatRate
  end

  class InvoicePaymentDateSet < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
    attribute :payment_date, Infra::Types::Params::Date
  end

  class InvoiceIssued < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
    attribute :issue_date, Infra::Types::Params::Date
    attribute :disposal_date, Infra::Types::Params::Date
    attribute :invoice_number, Infra::Types::String
  end

  class BillingAddressSet < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
    attribute :tax_id_number, Infra::Types::String.optional
    attribute :postal_address, Infra::Types::PostalAddress
  end

  class ProductNameDisplayedSet < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :name_displayed, Infra::Types::String
  end
end