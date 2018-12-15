require 'test_helper'

module Payments
  class PaymentTest < ActiveSupport::TestCase
    include TestCase
    cover 'Payments::Payment*'

    test 'authorize' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid

      payment = Payment.new
      payment.authorize(transaction_id, order_id)
      assert_changes(payment.unpublished_events, [
        PaymentAuthorized.new(data: {
          transaction_id: transaction_id,
          order_id: order_id,
        })
      ])
    end

    test 'should not allow for double authorization' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid

      payment = Payment.new
      payment.apply(
        PaymentAuthorized.new(data: {
          transaction_id: transaction_id,
          order_id: order_id,
        })
      )
      assert_raises(AlreadyAuthorized) do
        payment.authorize(transaction_id, order_id)
      end
    end

  end
end
