require "test_helper"

module Invoices
  class AssignStoreToInvoiceTest < InMemoryRESIntegrationTestCase
    cover "Invoices*"

    def test_assigns_store_to_invoice
      event_store = Rails.configuration.event_store
      store_id = SecureRandom.uuid
      invoice_id = SecureRandom.uuid

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
        Stores::InvoiceRegistered.new(
          data: {
            store_id: store_id,
            invoice_id: invoice_id
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: invoice_id)
      assert_equal(store_id, invoice.store_id)
    end
  end
end
