require_relative 'test_helper'

module Payments
  class OnReleasePaymentTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Payments::OnReleasePayment*'

    test 'capture payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"

      arrange(
        AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id)
      )

      assert_events(
        stream,
        PaymentReleased.new(
          data: {
            transaction_id: transaction_id,
            order_id: order_id
          }
        )
      ) do
        act(
          ReleasePayment.new(transaction_id: transaction_id, order_id: order_id)
        )
      end
    end
  end
end
