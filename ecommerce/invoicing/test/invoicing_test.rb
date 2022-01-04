require_relative "test_helper"

module Invoicing
  class InvoicingTest < Test
    cover "Invoicing::AddInvoiceItemHandler"

    def test_generate_invoice
      assert true
    end

    def test_adding_to_invoice
      invoice_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      unit_price = 10.0.to_d
      vat_rate = Infra::Types::VatRate.new(code: "20", rate: 20)

      stream = "Invoicing::Invoice$#{invoice_id}"

      assert_events(
        stream,
        InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id,
            product_id: product_id,
            vat_rate: vat_rate,
            unit_price: unit_price,
            quantity: 1,
          }
        )
      ) { act(AddInvoiceItem.new(invoice_id: invoice_id, product_id: product_id, vat_rate: vat_rate, unit_price: unit_price, quantity: 1)) }
    end
  end
end
