require_relative "test_helper"

module Processes
  class ReleasePaymentProcessTest < Test
    cover "Processes::ReleasePaymentProcess*"

    def test_happy_path
      process = ReleasePaymentProcess.new(event_store, command_bus)
      given([order_pre_submitted, payment_authorized, order_confirmed]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_order_expired_without_payment
      process = ReleasePaymentProcess.new(event_store, command_bus)
      given([order_pre_submitted, order_expired]).each { |event| process.call(event) }
      assert_no_command
    end

    def test_order_expired_after_payment_authorization
      process = ReleasePaymentProcess.new(event_store, command_bus)
      given([order_pre_submitted, payment_authorized, order_expired]).each do |event|
        process.call(event)
      end
      assert_command(Payments::ReleasePayment.new(order_id: order_id),)
    end

    def test_order_expired_after_payment_released
      process = ReleasePaymentProcess.new(event_store, command_bus)
      given([order_pre_submitted, payment_authorized, payment_released, order_expired]).each do |event|
        process.call(event)
      end
      assert_no_command
    end
  end
end