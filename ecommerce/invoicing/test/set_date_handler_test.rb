module Invoicing
  class SetDateHandlerTest < Test
    cover "Invoicing::SetDateHandler"

    def test_setting_payment_date
      invoice_id = SecureRandom.uuid
      payment_date = Date.new(2021, 1, 5)
      stream = "Invoicing::Invoice$#{invoice_id}"

      assert_events(
        stream,
        PaymentDateSet.new(
          data: {
            invoice_id: invoice_id,
            payment_date: payment_date,
          }
        )
      ) { act(SetPaymentDate.new(invoice_id: invoice_id, payment_date: payment_date)) }
    end

    def test_setting_disposal_date
      invoice_id = SecureRandom.uuid
      disposal_date = Date.new(2021, 1, 5)
      stream = "Invoicing::Invoice$#{invoice_id}"

      assert_events(
        stream,
        DisposalDateSet.new(
          data: {
            invoice_id: invoice_id,
            disposal_date: disposal_date,
          }
        )
      ) { act(SetDisposalDate.new(invoice_id: invoice_id, disposal_date: disposal_date)) }
    end
  end
end