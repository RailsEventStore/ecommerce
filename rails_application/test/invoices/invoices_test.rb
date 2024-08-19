require "test_helper"

module Invoices
  class InvoicesTest < InMemoryRESIntegrationTestCase
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

    def test_product_name_change_affects_existing_invoices
      product_id = SecureRandom.uuid
      initial_product_name = "Initial Name"
      updated_product_name = "Updated Name"

      add_available_vat_rate(20)
      product_id = register_product(initial_product_name, 100, 20)
      customer_id = register_customer("Test Customer")

      order_id = SecureRandom.uuid
      add_product_to_basket(order_id, product_id)
      submit_order(customer_id, order_id)

      update_product_name(product_id, updated_product_name)

      assert_invoice_product_name(order_id, initial_product_name)

      new_order_id = SecureRandom.uuid
      add_product_to_basket(new_order_id, product_id)
      submit_order(customer_id, new_order_id)

      assert_invoice_product_name(new_order_id, updated_product_name)
    end

    private

    def update_product_name(product_id, new_name)
      patch "/products/#{product_id}",
            params: {
              "authenticity_token" => "[FILTERED]",
              "product_id" => product_id,
              name: new_name,
            }
    end

    def assert_invoice_product_name(order_id, expected_name)
      get "/invoices/#{order_id}"
      assert_response :success
      assert_select ".py-2", text: expected_name
    end
  end
end
