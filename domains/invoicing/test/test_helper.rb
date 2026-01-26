require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/invoicing"
require_relative '../lib/invoicing/fake_concurrent_invoice_number_generator'

module Invoicing
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    private

    def set_product_name_displayed(product_id, name_displayed)
      run_command(SetProductNameDisplayedOnInvoice.new(product_id: product_id, name_displayed: name_displayed))
    end

    def set_billing_address(invoice_id, postal_address = fake_address, tax_id_number = nil)
      run_command(SetBillingAddress.new(
        invoice_id: invoice_id,
        postal_address: postal_address,
        tax_id_number: tax_id_number
      ))
    end

    def fake_address
      Infra::Types::PostalAddress.new(
        line_1: "Anna Kowalska",
        line_2: "Ul. Bosmanska 1",
        line_3: "81-116 GDYNIA",
        line_4: "POLAND"
      )
    end
  end
end
