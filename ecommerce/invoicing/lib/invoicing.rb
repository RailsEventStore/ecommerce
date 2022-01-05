require 'infra'
require_relative 'invoicing/commands'
require_relative 'invoicing/events'
require_relative 'invoicing/services'
require_relative 'invoicing/invoice'
require_relative 'invoicing/invoice_item_title_catalog'
require_relative 'invoicing/product'

module Invoicing
  class Configuration
    def call(cqrs)
      cqrs.register_command(AddInvoiceItem, AddInvoiceItemHandler.new(cqrs.event_store), InvoiceItemAdded)
      cqrs.register_command(
        SetProductNameDisplayedOnInvoice,
        SetProductNameDisplayedOnInvoiceHandler.new(cqrs.event_store),
        ProductNameDisplayedSet
      )
      cqrs.register_command(
        SetDisposalDate,
        SetDateHandler.new(cqrs.event_store).public_method(:set_disposal_date),
        DisposalDateSet
      )
      cqrs.register_command(
        SetPaymentDate,
        SetDateHandler.new(cqrs.event_store).public_method(:set_payment_date),
        PaymentDateSet
      )
    end
  end
end