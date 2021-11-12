require_relative "test_helper"

module Payments
  class OnCapturePaymentTest < Test
    cover "Payments::OnCapturePayment*"

    def test_capture_payment
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{order_id}"

      arrange(
        SetPaymentAmount.new(order_id: order_id, amount: 20),
        AuthorizePayment.new(order_id: order_id)
      )

      assert_equal(20, payment_gateway.authorized_transactions[0][1])

      assert_events(
        stream,
        PaymentCaptured.new(data: { order_id: order_id })
      ) { act(CapturePayment.new(order_id: order_id)) }
    end
  end
end
