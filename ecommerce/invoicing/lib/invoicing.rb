require "infra"

module Invoicing
  class Configuration
    def self.AVAILABLE_VAT_RATES
      @@available_vat_rates
    end

    def initialize available_vat_rates = []
      @available_vat_rates = available_vat_rates
    end

    def call(cqrs)
      @@available_vat_rates = @available_vat_rates
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