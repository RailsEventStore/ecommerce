require "test_helper"

module Processes
  class OrderConfirmationTest < ProcessTest
    cover "Processes::OrderConfirmation"

    def test_payment_confirms_order
      process = ConfirmOrderOnPaymentCaptured.new(command_bus)
      given([payment_authorized]).each do |event|
        process.call(event)
      end
      assert_instance_of(Fulfillment::ConfirmOrder, command_bus.received)
      assert_equal(order_id, command_bus.received.order_id)
    end
  end
end
