require 'infra'
require_relative 'invoicing/commands'
require_relative 'invoicing/events'
require_relative 'invoicing/services'
require_relative 'invoicing/product'

module Invoicing
  class Configuration
    def self.AVAILABLE_VAT_RATES
      @@available_vat_rates
    end

    def initialize(available_vat_rates = [])
      @available_vat_rates = available_vat_rates
    end

    def call(cqrs)
      @@available_vat_rates = @available_vat_rates
      cqrs.register_command(GenerateInvoice, GenerateInvoiceHandler.new, InvoiceGenerated)
      cqrs.register_command(SetVatRate, SetVatRateHandler.new(cqrs.event_store), VatRateSet)
    end
  end
end