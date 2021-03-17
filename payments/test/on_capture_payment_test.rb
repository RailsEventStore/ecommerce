require_relative 'test_helper'

module Payments
  class OnCapturePaymentTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Payments::OnCapturePayment*'

    test 'capture payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"

      arrange(
        AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id)
      )

      assert_events(
        stream,
        PaymentCaptured.new(
          data: {
            transaction_id: transaction_id,
            order_id: order_id
          }
        )
      ) do
        act(
          CapturePayment.new(transaction_id: transaction_id, order_id: order_id)
        )
      end
    end
  end
end
