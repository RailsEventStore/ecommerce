require "test_helper"

module Invoices
  class MarkOrderPlacedTest < InMemoryRESIntegrationTestCase
    cover "Invoices*"

    def test_creates_invoice_and_marks_order_as_submitted
      event_store = Rails.configuration.event_store
      order_id = SecureRandom.uuid

      event_store.publish(
        Invoicing::InvoiceItemAdded.new(
          data: {
            invoice_id: order_id,
            product_id: SecureRandom.uuid,
            title: "Test Product",
            quantity: 1,
            unit_price: 100,
            vat_rate: { rate: 20, code: "VAT" }
          }
        )
      )

      event_store.publish(
        Fulfillment::OrderRegistered.new(
          data: {
            order_id: order_id,
            order_number: Fulfillment::FakeNumberGenerator::FAKE_NUMBER
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: order_id)
      assert_equal(order_id, invoice.order_uid)
      assert_equal(false, invoice.new_record?)

      order = Order.find_by!(uid: order_id)
      assert_equal(order_id, order.uid)
      assert_equal(true, order.submitted)
    end

    def test_creates_invoice_when_order_registered_before_items_added
      event_store = Rails.configuration.event_store
      order_id = SecureRandom.uuid

      event_store.publish(
        Fulfillment::OrderRegistered.new(
          data: {
            order_id: order_id,
            order_number: Fulfillment::FakeNumberGenerator::FAKE_NUMBER
          }
        )
      )

      invoice = Invoice.find_by!(order_uid: order_id)
      assert_equal(order_id, invoice.order_uid)
      assert_equal(false, invoice.new_record?)
    end
  end
end
