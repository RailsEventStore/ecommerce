require_relative "test_helper"

module Processes
  class OrderConfirmationTest < Test
    cover "Processes::OrderConfirmation"

    def test_payment_confirms_order
      process = ConfirmOrderOnPaymentCaptured.new(command_bus)
      given([payment_authorized]).each do |event|
        process.call(event)
      end
      assert_command(Ordering::ConfirmOrder.new(order_id: order_id))
    end
  end
end
