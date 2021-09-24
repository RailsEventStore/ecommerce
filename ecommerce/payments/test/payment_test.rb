require_relative "test_helper"

module Payments
  class PaymentTest < Test
    cover "Payments::Payment*"

    def test_authorize_publishes_event
      payment = Payment.new
      gateway = FakeGateway.new
      payment.set_amount(order_id, 20)
      payment.authorize(order_id, gateway)
      assert_changes(
        payment.unpublished_events,
        [
          PaymentAmountSet.new(data: { order_id: order_id, amount: 20 }),
          PaymentAuthorized.new(data: { order_id: order_id })
        ]
      )
    end

    def test_authorize_contacts_gateway
      payment = Payment.new
      gateway = FakeGateway.new
      payment.set_amount(order_id, 20)
      payment.authorize(order_id, gateway)
      assert(gateway.authorized_transactions.include?([order_id, 20]))
    end

    def test_should_not_allow_for_double_authorization
      assert_raises(Payment::AlreadyAuthorized) do
        authorized_payment.authorize(order_id, nil)
      end
    end

    def test_should_capture_authorized_payment
      payment = authorized_payment
      before = payment.unpublished_events.to_a

      payment.capture
      actual = payment.unpublished_events.to_a - before
      assert_changes(
        actual,
        [PaymentCaptured.new(data: { order_id: order_id })]
      )
    end

    def test_must_not_capture_not_authorized_payment
      assert_raises(Payment::NotAuthorized) { Payment.new.capture }
    end

    def test_should_not_allow_for_double_capture
      assert_raises(Payment::AlreadyCaptured) { captured_payment.capture }
    end

    def test_authorization_could_be_released
      payment = authorized_payment
      before = payment.unpublished_events.to_a

      payment.release
      actual = payment.unpublished_events.to_a - before
      assert_changes(
        actual,
        [PaymentReleased.new(data: { order_id: order_id })]
      )
    end

    def test_must_not_release_not_captured_payment
      assert_raises(Payment::AlreadyCaptured) { captured_payment.release }
    end

    def test_must_not_release_not_authorized_payment
      assert_raises(Payment::NotAuthorized) { Payment.new.release }
    end

    def test_should_not_allow_for_double_release
      assert_raises(Payment::AlreadyReleased) { released_payment.release }
    end

    private

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def authorized_payment
      Payment.new.tap do |payment|
        payment.apply(PaymentAuthorized.new(data: { order_id: order_id }))
      end
    end

    def captured_payment
      authorized_payment.tap do |payment|
        payment.apply(PaymentCaptured.new(data: { order_id: order_id }))
      end
    end

    def released_payment
      captured_payment.tap do |payment|
        payment.apply(PaymentReleased.new(data: { order_id: order_id }))
      end
    end
  end
end
