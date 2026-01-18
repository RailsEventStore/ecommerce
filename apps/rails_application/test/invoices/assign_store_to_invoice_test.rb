require "test_helper"

module Invoices
  class AssignStoreToInvoiceTest < InMemoryTestCase
    cover "Invoices*"

    def test_assigns_store_to_invoice
      event_store = Rails.configuration.event_store
      store_id = SecureRandom.uuid
      invoice_id = SecureRandom.uuid

      event_store.publish(
        Stores::InvoiceRegistered.new(
          data: {
            store_id: store_id,
            invoice_id: invoice_id
          }
        )
      )

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

      invoice = Invoice.find_by!(order_uid: invoice_id)
      assert_equal(store_id, invoice.store_id)
    end

    def test_assigns_store_to_correct_invoice_when_multiple_invoices_exist
      event_store = Rails.configuration.event_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      invoice_id_1 = SecureRandom.uuid
      invoice_id_2 = SecureRandom.uuid

      event_store.publish(
        Stores::InvoiceRegistered.new(
          data: {
            store_id: store_id_1,
            invoice_id: invoice_id_1
          }
        )
      )

      event_store.publish(
        Stores::InvoiceRegistered.new(
          data: {
            store_id: store_id_2,
            invoice_id: invoice_id_2
          }
        )
      )
      event_store.publish(
        Invoicing::InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id_1,
            product_id: SecureRandom.uuid,
            title: "Test Product 1",
            quantity: 1,
            unit_price: 100,
            vat_rate: { rate: 20, code: "VAT" }
          }
        )
      )

      event_store.publish(
        Invoicing::InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id_2,
            product_id: SecureRandom.uuid,
            title: "Test Product 2",
            quantity: 1,
            unit_price: 100,
            vat_rate: { rate: 20, code: "VAT" }
          }
        )
      )

      invoice_1 = Invoice.find_by!(order_uid: invoice_id_1)
      invoice_2 = Invoice.find_by!(order_uid: invoice_id_2)
      assert_equal(store_id_1, invoice_1.store_id)
      assert_equal(store_id_2, invoice_2.store_id)
    end

    def test_returns_nil_when_invoice_exists_in_different_store
      event_store = Rails.configuration.event_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      invoice_id = SecureRandom.uuid

      event_store.publish(
        Stores::InvoiceRegistered.new(
          data: {
            store_id: store_id_1,
            invoice_id: invoice_id
          }
        )
      )

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

      assert_nil Invoices.find_invoice_in_store(invoice_id, store_id_2)
      assert_not_nil Invoices.find_invoice_in_store(invoice_id, store_id_1)
    end
  end
end
