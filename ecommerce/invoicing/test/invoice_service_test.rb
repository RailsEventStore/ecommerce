require_relative "test_helper"

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

    def test_setting_billing_address
      invoice_id = SecureRandom.uuid
      billing_address = fake_address
      tax_id_number = "PL1111111111"
      stream = "Invoicing::Invoice$#{invoice_id}"
      assert_events(
        stream,
        BillingAddressSet.new(
          data: {
            invoice_id: invoice_id,
            postal_address: fake_address,
            tax_id_number: tax_id_number
          }
        )
      ) { set_billing_address(invoice_id, billing_address, tax_id_number) }
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
      set_billing_address(invoice_id)

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
      set_billing_address(invoice_id)

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

    def test_issuing_invoice_with_faked_race_condition
      invoice_id = SecureRandom.uuid
      another_invoice_id = SecureRandom.uuid
      issue_date = Date.new(2021, 1, 5)
      set_billing_address(invoice_id)
      set_billing_address(another_invoice_id)

      mocked_service = InvoiceService.new(
        event_store,
        FakeConcurrentInvoiceNumberGenerator.new
      ).public_method(:issue)

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
      ) { mocked_service.(issue_invoice_command(invoice_id, issue_date)) }
      assert_raises(Invoice::InvoiceNumberInUse) do
        mocked_service.(issue_invoice_command(another_invoice_id, issue_date))
      end
    end

    def test_issued_invoice_is_a_final_state
      invoice_id = SecureRandom.uuid
      set_billing_address(invoice_id)
      issue_invoice(invoice_id)
      assert_raises(Invoice::InvoiceAlreadyIssued) { issue_invoice(invoice_id) }
      assert_raises(Invoice::InvoiceAlreadyIssued) { add_item(invoice_id) }
      assert_raises(Invoice::InvoiceAlreadyIssued) { set_billing_address(invoice_id) }
    end

    def test_invoice_can_not_be_issued_without_billing_address
      invoice_id = SecureRandom.uuid
      assert_raises(Invoice::BillingAddressNotSpecified) { issue_invoice(invoice_id) }
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
      run_command(issue_invoice_command(invoice_id, issue_date))
    end

    def issue_invoice_command(invoice_id, issue_date)
      IssueInvoice.new(invoice_id: invoice_id, issue_date: issue_date)
    end

    def set_payment_date(invoice_id, payment_date = Date.new(2021, 1, 5))
      run_command(SetPaymentDate.new(invoice_id: invoice_id, payment_date: payment_date))
    end
  end
end