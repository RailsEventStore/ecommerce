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
    def call(event_store, command_bus)
      command_bus.register(
        SetProductNameDisplayedOnInvoice,
        SetProductNameDisplayedOnInvoiceHandler.new(event_store)
      )
      command_bus.register(
        AddInvoiceItem,
        InvoiceService.new(event_store).public_method(:add_item)
      )
      command_bus.register(
        SetPaymentDate,
        InvoiceService.new(event_store).public_method(:set_payment_date)
      )
      command_bus.register(
        IssueInvoice,
        InvoiceService.new(event_store).public_method(:issue)
      )
      command_bus.register(
        SetBillingAddress,
        InvoiceService.new(event_store).public_method(:set_billing_address)
      )
      event_store.subscribe(
        ->(event) do
          stream_name = "InvoiceIssued$#{event.data.fetch(:issue_date).strftime("%Y-%m")}"
          ordinal_number = event.data.fetch(:invoice_number).split('/').first.to_i
          event_store.link(
            event.event_id,
            stream_name: stream_name,
            expected_version: ordinal_number - 2
          )
        rescue RubyEventStore::WrongExpectedEventVersion
          raise Invoice::InvoiceNumberInUse
        end,
        to: [Invoicing::InvoiceIssued]
      )
    end
  end
end