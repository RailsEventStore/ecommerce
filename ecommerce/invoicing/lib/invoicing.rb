require 'infra'
require_relative 'invoicing/commands'
require_relative 'invoicing/events'
require_relative 'invoicing/services'
require_relative 'invoicing/invoice'

module Invoicing
  class Configuration
    def call(cqrs)
      cqrs.register_command(AddInvoiceItem, AddInvoiceItemHandler.new(cqrs.event_store), InvoiceItemAdded)
    end
  end
end