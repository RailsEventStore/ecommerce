module Invoicing
  class AddInvoiceItem < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :quantity, Infra::Types::Quantity
    attribute :unit_price, Infra::Types::Price
    attribute :vat_rate, Infra::Types::VatRate
  end

  class IssueInvoice < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :issue_date, Infra::Types::Date
  end

  class SetPaymentDate < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :payment_date, Infra::Types::Date
  end

  class SetBillingAddress < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :tax_id_number, Infra::Types::String.optional
    attribute :postal_address, Infra::Types::PostalAddress
  end

  class SetProductNameDisplayedOnInvoice < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :name_displayed, Infra::Types::String
  end
end