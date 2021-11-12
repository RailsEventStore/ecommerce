require_relative "test_helper"

module Payments
  class OnReleasePaymentTest < Test
    cover "Payments::OnReleasePayment*"

    def test_capture_payment
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{order_id}"

      arrange(
        AuthorizePayment.new(order_id: order_id)
      )

      assert_events(
        stream,
        PaymentReleased.new(data: { order_id: order_id })
      ) { act(ReleasePayment.new(order_id: order_id)) }
    end
  end
end
