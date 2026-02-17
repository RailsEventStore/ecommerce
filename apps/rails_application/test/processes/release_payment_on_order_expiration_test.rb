require "test_helper"

module Processes
  class ReleasePaymentOnOrderExpirationTest < ProcessTest
    cover "Processes::ReleasePaymentOnOrderExpiration*"

    def test_happy_path
      process = ReleasePaymentOnOrderExpiration.new(event_store, command_bus)
      given([order_placed, payment_authorized, order_confirmed]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_order_expired_without_payment
      process = ReleasePaymentOnOrderExpiration.new(event_store, command_bus)
      given([order_placed, order_expired]).each { |event| process.call(event) }
      assert_no_command
    end

    def test_order_expired_after_payment_authorization
      process = ReleasePaymentOnOrderExpiration.new(event_store, command_bus)
      given([order_placed, payment_authorized, order_expired]).each do |event|
        process.call(event)
      end
      assert_command(Payments::ReleasePayment.new(order_id: order_id),)
    end

    def test_order_expired_after_payment_released
      process = ReleasePaymentOnOrderExpiration.new(event_store, command_bus)
      given([order_placed, payment_authorized, payment_released, order_expired]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_separate_orders_do_not_interfere
      other_order_id = SecureRandom.uuid
      process = ReleasePaymentOnOrderExpiration.new(event_store, command_bus)

      given([
        order_placed,
        payment_authorized,
        Fulfillment::OrderRegistered.new(data: { order_id: other_order_id, order_number: "2024/01/01" }),
        Payments::PaymentAuthorized.new(data: { order_id: other_order_id }),
      ]).each { |event| process.call(event) }

      given([order_expired]).each { |event| process.call(event) }
      assert_command(Payments::ReleasePayment.new(order_id: order_id))
    end
  end
end