module Invoicing
  class GenerateInvoice < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
  end
end