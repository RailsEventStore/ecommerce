module Invoicing
  class AddInvoiceItem < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :quantity, Infra::Types::Quantity
    attribute :unit_price, Infra::Types::Price
    attribute :vat_rate, Infra::Types::VatRate
  end

  class SetDisposalDate < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :disposal_date, Infra::Types::Date
  end

  class SetPaymentDate < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :payment_date, Infra::Types::Date
  end

  class SetProductNameDisplayedOnInvoice < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :name_displayed, Infra::Types::String
  end
end