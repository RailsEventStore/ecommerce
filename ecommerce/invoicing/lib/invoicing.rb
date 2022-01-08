require 'infra'
require_relative 'invoicing/commands'
require_relative 'invoicing/events'
require_relative 'invoicing/services'
require_relative 'invoicing/invoice'
require_relative 'invoicing/invoice_item_title_catalog'
require_relative 'invoicing/product'
require_relative 'invoicing/invoice_number_generator'

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
      cqrs.register_command(
        SetBillingAddress,
        InvoiceService.new(cqrs.event_store).public_method(:set_billing_address),
        BillingAddressSet
      )
      cqrs.subscribe(
        ->(event) do
          stream_name = "InvoiceIssued$#{event.data.fetch(:issue_date).strftime("%Y-%m")}"
          ordinal_number = event.data.fetch(:invoice_number).split('/').first.to_i
          cqrs.event_store.link(
            event.event_id,
            stream_name: stream_name,
            expected_version: ordinal_number - 2
          )
        rescue RubyEventStore::WrongExpectedEventVersion
          raise Invoice::InvoiceNumberInUse
        end,
        [Invoicing::InvoiceIssued]
      )
    end
  end
end