require_relative 'test_helper'

module Payments
  class OnAuthorizePaymentTest < ActiveSupport::TestCase
    include TestCase

    test 'authorize payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"

      published = act(stream, AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id))

      assert_changes(published, [PaymentAuthorized.new(data: {transaction_id: transaction_id, order_id: order_id})])
    end
  end
end

