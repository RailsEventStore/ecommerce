require_relative 'test_helper'

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
      assert_raises(Payment::AlreadyAuthorized) do
        authorized_payment.authorize(transaction_id, order_id)
      end
    end

    test 'should capture authorized payment' do
      payment = authorized_payment
      before = payment.unpublished_events.to_a

      payment.capture
      actual = payment.unpublished_events.to_a - before
      assert_changes(actual, [
        PaymentCaptured.new(data: {
          transaction_id: transaction_id,
          order_id: order_id,
        })
      ])
    end

    test 'must not capture not authorized payment' do
      assert_raises(Payment::NotAuthorized) do
        Payment.new.capture
      end
    end

    test 'should not allow for double capture' do
      assert_raises(Payment::AlreadyCaptured) do
        captured_payment.capture
      end
    end

    test 'authorization could be released' do
      payment = authorized_payment
      before = payment.unpublished_events.to_a

      payment.release
      actual = payment.unpublished_events.to_a - before
      assert_changes(actual, [
        PaymentReleased.new(data: {
          transaction_id: transaction_id,
          order_id: order_id,
        })
      ])
    end

    test 'must not release not captured payment' do
      assert_raises(Payment::AlreadyCaptured) do
        captured_payment.release
      end
    end

    test 'must not release not authorized payment' do
      assert_raises(Payment::NotAuthorized) do
        Payment.new.release
      end
    end

    test 'should not allow for double release' do
      assert_raises(Payment::AlreadyReleased) do
        released_payment.release
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

    def captured_payment
      authorized_payment.tap do |payment|
        payment.apply(
          PaymentCaptured.new(data: {
            transaction_id: transaction_id,
            order_id: order_id,
          })
        )
      end
    end

    def released_payment
      captured_payment.tap do |payment|
        payment.apply(
          PaymentReleased.new(data: {
            transaction_id: transaction_id,
            order_id: order_id,
          })
        )
      end
    end
  end
end
