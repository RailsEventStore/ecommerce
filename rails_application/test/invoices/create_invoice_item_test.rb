require "test_helper"

module Invoices
  class CreateInvoiceItemTest < InMemoryRESIntegrationTestCase
    cover "Invoices*"

    def test_creates_invoice_item_with_all_fields
      event_store = Rails.configuration.event_store
      invoice_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      title = "Test Product"
      quantity = 2
      unit_price = 100
      vat_rate = 20

      event_store.publish(
        Invoicing::InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id,
            product_id: product_id,
            title: title,
            quantity: quantity,
            unit_price: unit_price,
            vat_rate: { rate: vat_rate, code: "VAT" }
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: invoice_id)
      assert_equal(200, invoice.total_value)

      item = InvoiceItem.find_by!(invoice: invoice)
      assert_equal(title, item.name)
      assert_equal(quantity, item.quantity)
      assert_equal(unit_price, item.unit_price)
      assert_equal(vat_rate, item.vat_rate)
      assert_equal(200, item.value)
    end

    def test_accumulates_total_value_for_multiple_items
      event_store = Rails.configuration.event_store
      invoice_id = SecureRandom.uuid

      event_store.publish(
        Invoicing::InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id,
            product_id: SecureRandom.uuid,
            title: "Product 1",
            quantity: 1,
            unit_price: 100,
            vat_rate: { rate: 20, code: "VAT" }
          }
        )
      )

      event_store.publish(
        Invoicing::InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id,
            product_id: SecureRandom.uuid,
            title: "Product 2",
            quantity: 2,
            unit_price: 50,
            vat_rate: { rate: 20, code: "VAT" }
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: invoice_id)
      assert_equal(200, invoice.total_value)
      assert_equal(2, invoice.invoice_items.count)
    end
  end
end
