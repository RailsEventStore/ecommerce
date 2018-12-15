require 'test_helper'

module Payments
  class PaymentTest < ActiveSupport::TestCase
    include TestCase
    cover 'Payments::Payment*'

    test 'authorize' do
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
      assert_raises(Payments::AlreadyAuthorized) do
        authorized_payment.authorize(transaction_id, order_id)
      end
    end

    private
    def transaction_id
      @transaction_id ||= SecureRandom.hex(16)
    end

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def authorized_payment
      Payment.new.tap do |payment|
        payment.apply(
          PaymentAuthorized.new(data: {
            transaction_id: transaction_id,
            order_id: order_id,
          })
        )
      end
    end
  end
end
