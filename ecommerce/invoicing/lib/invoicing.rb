require 'infra'
require_relative 'invoicing/commands'
require_relative 'invoicing/events'
require_relative 'invoicing/services'

module Invoicing
  class Configuration
    def call(cqrs)
      cqrs.register_command(GenerateInvoice, GenerateInvoiceHandler.new, InvoiceGenerated)
      end
  end
end