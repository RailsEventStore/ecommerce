require "test_helper"

module Invoices
  class SetBillingAddressTest < InMemoryRESIntegrationTestCase
    cover "Invoices*"

    def test_sets_billing_address_with_all_fields
      event_store = Rails.configuration.event_store
      invoice_id = SecureRandom.uuid
      tax_id = "1234567890"

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
        Invoicing::BillingAddressSet.new(
          data: {
            invoice_id: invoice_id,
            tax_id_number: tax_id,
            postal_address: {
              line_1: "123 Main St",
              line_2: "Apt 4",
              line_3: "New York, NY 10001",
              line_4: "USA"
            }
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: invoice_id)
      assert_equal(true, invoice.address_present)
      assert_equal(tax_id, invoice.tax_id_number)
      assert_equal("123 Main St", invoice.address_line_1)
      assert_equal("Apt 4", invoice.address_line_2)
      assert_equal("New York, NY 10001", invoice.address_line_3)
      assert_equal("USA", invoice.address_line_4)
    end
  end
end
