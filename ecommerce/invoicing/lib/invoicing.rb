require "infra"

module Invoicing
  class Configuration
    def call(cqrs)
      cqrs.register_command(GenerateInvoice, GenerateInvoiceHandler.new, InvoiceGenerated)
    end
  end

  class GenerateInvoice < Infra::Command
    attribute :invoice_id, Infra::Types::UUID
  end

  class InvoiceGenerated < Infra::Event
    attribute :invoice_id, Infra::Types::UUID
  end

  class GenerateInvoiceHandler
    def call(cmd)
    end
  end
end