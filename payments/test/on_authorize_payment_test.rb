require_relative 'test_helper'

module Payments
  class OnAuthorizePaymentTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Payments::OnAuthorizePayment*'

    test 'authorize payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"

      assert_events(
        stream,
        PaymentAuthorized.new(
          data: {
            transaction_id: transaction_id,
            order_id: order_id
          }
        )
      ) do
        act(
          AuthorizePayment.new(
            transaction_id: transaction_id,
            order_id: order_id
          )
        )
      end
    end
  end
end
