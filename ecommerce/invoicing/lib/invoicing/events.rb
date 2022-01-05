module Invoicing
  class InvoiceItemAdded < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :title, Infra::Types::String
    attribute :quantity, Infra::Types::Quantity
    attribute :unit_price, Infra::Types::Price
    attribute :vat_rate, Infra::Types::VatRate
  end

  class ProductNameDisplayedSet < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :name_displayed, Infra::Types::String
  end
end