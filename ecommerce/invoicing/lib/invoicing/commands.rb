module Invoicing
  class AddInvoiceItem < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :quantity, Infra::Types::Quantity
    attribute :unit_price, Infra::Types::Price
    attribute :vat_rate, Infra::Types::VatRate
  end
end