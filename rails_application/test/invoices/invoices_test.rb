require "test_helper"

module Invoices
  class InvoicesTest < InMemoryTestCase
    cover "Invoices*"

    def setup
      super
      Invoice.destroy_all
      InvoiceItem.destroy_all
      Order.destroy_all
    end

    def test_create_draft_order_when_not_exists
      event_store = Rails.configuration.event_store
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      event_store.publish(
        [
          Invoicing::InvoiceItemAdded.new(data: { invoice_id: order_id, product_id: product_id, title: "dummy",  discounted_amount: 9, quantity: 1, amount: 1, unit_price: 10, vat_rate: { rate: 23, code: "VAT" } }),
          Invoicing::InvoiceItemAdded.new(data: { invoice_id: order_id, product_id: product_id, title: "dummy2", discounted_amount: 9, quantity: 1, amount: 1, unit_price: 8, vat_rate: { rate: 23, code: "VAT" } }),
        ]
      )
      assert_equal(Invoice.count, 1)
      assert_equal(18, Invoice.last.total_value)
    end
  end
end