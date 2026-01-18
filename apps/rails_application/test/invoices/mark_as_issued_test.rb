require "test_helper"

module Invoices
  class MarkAsIssuedTest < InMemoryTestCase
    cover "Invoices*"

    def test_marks_invoice_as_issued_with_all_fields
      event_store = Rails.configuration.event_store
      invoice_id = SecureRandom.uuid
      issue_date = Date.today
      disposal_date = Date.today + 30
      invoice_number = Invoicing::InvoiceNumberGenerator.new(event_store).call(issue_date)

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
        Invoicing::InvoiceIssued.new(
          data: {
            invoice_id: invoice_id,
            issue_date: issue_date,
            disposal_date: disposal_date,
            invoice_number: invoice_number
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: invoice_id)
      assert_equal(true, invoice.issued)
      assert_equal(issue_date, invoice.issue_date)
      assert_equal(disposal_date, invoice.disposal_date)
      assert_equal(invoice_number, invoice.number)
    end
  end
end
