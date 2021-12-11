module Invoicing
  class InvoiceGenerated < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
  end
end