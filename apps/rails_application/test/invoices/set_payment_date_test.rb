require "test_helper"

module Invoices
  class SetPaymentDateTest < InMemoryTestCase
    cover "Invoices*"

    def configure(event_store, _command_bus)
      Invoices::Configuration.new.call(event_store)
    end

    def test_sets_payment_date_on_invoice
      event_store = Rails.configuration.event_store
      invoice_id = SecureRandom.uuid
      payment_date = Date.today

      event_store.publish(
        Invoicing::InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id,
            product_id: SecureRandom.uuid,
            title: "Test Product",
            quantity: 1,
            unit_price: 100,
            vat_rate: { rate: 20, code: "VAT" }
          }
        )
      )

      event_store.publish(
        Invoicing::InvoicePaymentDateSet.new(
          data: {
            invoice_id: invoice_id,
            payment_date: payment_date
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: invoice_id)
      assert_equal(payment_date, invoice.payment_date)
    end
  end
end
