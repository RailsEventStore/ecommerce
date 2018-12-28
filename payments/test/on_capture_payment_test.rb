require_relative 'test_helper'

module Payments
  class OnCapturePaymentTest < ActiveSupport::TestCase
    include TestCase

    test 'capture payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"

      arrange(stream, [PaymentAuthorized.new(data: {transaction_id: transaction_id, order_id: order_id})])
      published = act(stream, CapturePayment.new(transaction_id: transaction_id, order_id: order_id))

      assert_changes(published, [PaymentCaptured.new(data: {transaction_id: transaction_id, order_id: order_id})])
    end
  end
end
