module Invoicing
  class InvoiceServiceTest < Test
    cover "Invoicing::InvoiceService"

    def test_adding_to_invoice
      invoice_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      unit_price = 10.0.to_d
      vat_rate = Infra::Types::VatRate.new(code: "20", rate: 20)
      title = 'test'

      stream = "Invoicing::Invoice$#{invoice_id}"
      assert_events(
        stream,
        InvoiceItemAdded.new(
          data: {
            invoice_id: invoice_id,
            product_id: product_id,
            title: title,
            vat_rate: vat_rate,
            unit_price: unit_price,
            quantity: 1,
          }
        )
      ) { add_item(invoice_id, product_id, vat_rate, unit_price, title) }
    end

    def test_setting_payment_date
      invoice_id = SecureRandom.uuid
      payment_date = Date.new(2021, 1, 5)
      stream = "Invoicing::Invoice$#{invoice_id}"

      assert_events(
        stream,
        InvoicePaymentDateSet.new(
          data: {
            invoice_id: invoice_id,
            payment_date: payment_date,
          }
        )
      ) { set_payment_date(invoice_id, payment_date) }
    end

    def test_issuing_invoice
      invoice_id = SecureRandom.uuid
      issue_date = Date.new(2021, 1, 5)
      stream = "Invoicing::Invoice$#{invoice_id}"
      assert_events(
        stream,
        InvoiceIssued.new(
          data: {
            invoice_id: invoice_id,
            issue_date: issue_date,
            disposal_date: issue_date,
            invoice_number: '1/01/2021'
          }
        )
      ) { issue_invoice(invoice_id, issue_date) }
    end

    def test_issuing_invoice_after_setting_payment_date
      invoice_id = SecureRandom.uuid
      issue_date = Date.new(2021, 1, 5)
      payment_date = Date.new(2021, 1, 1)
      set_payment_date(invoice_id, payment_date)

      stream = "Invoicing::Invoice$#{invoice_id}"
      assert_events(
        stream,
        InvoiceIssued.new(
          data: {
            invoice_id: invoice_id,
            issue_date: issue_date,
            disposal_date: payment_date,
            invoice_number: '1/01/2021'
          }
        )
      ) { issue_invoice(invoice_id, issue_date) }
    end

    def test_issued_invoice_is_a_final_state
      invoice_id = SecureRandom.uuid
      issue_invoice(invoice_id)
      assert_raises(Invoice::InvoiceAlreadyIssued) { issue_invoice(invoice_id) }
      assert_raises(Invoice::InvoiceAlreadyIssued) { set_payment_date(invoice_id) }
      assert_raises(Invoice::InvoiceAlreadyIssued) { add_item(invoice_id) }
    end

    private

    def add_item (
      invoice_id,
      product_id = SecureRandom.uuid,
      vat_rate = Infra::Types::VatRate.new(code: "20", rate: 20),
      unit_price = 10.0.to_d,
      title = 'test'
    )
      set_product_name_displayed(product_id, title)
      run_command(AddInvoiceItem.new(
        invoice_id: invoice_id,
        product_id: product_id,
        vat_rate: vat_rate,
        unit_price: unit_price,
        quantity: 1
      ))
    end

    def issue_invoice(invoice_id, issue_date = Date.new(2021, 1, 5))
      run_command(IssueInvoice.new(invoice_id: invoice_id, issue_date: issue_date))
    end

    def set_payment_date(invoice_id, payment_date = Date.new(2021, 1, 5))
      run_command(SetPaymentDate.new(invoice_id: invoice_id, payment_date: payment_date))
    end
  end
end