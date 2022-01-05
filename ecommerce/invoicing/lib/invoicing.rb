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
      cqrs.register_command(
        SetProductNameDisplayedOnInvoice,
        SetProductNameDisplayedOnInvoiceHandler.new(cqrs.event_store),
        ProductNameDisplayedSet
      )
      cqrs.register_command(
        AddInvoiceItem,
        InvoiceService.new(cqrs.event_store).public_method(:add_item),
        InvoiceItemAdded
      )
      cqrs.register_command(
        SetPaymentDate,
        InvoiceService.new(cqrs.event_store).public_method(:set_payment_date),
        InvoicePaymentDateSet
      )
      cqrs.register_command(
        IssueInvoice,
        InvoiceService.new(cqrs.event_store).public_method(:issue),
        InvoiceIssued
      )
    end
  end
end