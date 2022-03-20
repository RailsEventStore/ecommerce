require_relative "test_helper"

module Processes
  class OrderConfirmationTest < Test
    cover "Processes::OrderConfirmation"

    def test_authorized_is_not_enough_to_confirm
      process = OrderConfirmation.new(cqrs)
      given([order_submitted, payment_authorized]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_payment_confirms_order
      process = OrderConfirmation.new(cqrs)
      given([order_submitted, payment_authorized, payment_captured]).each do |event|
        process.call(event)
      end
      assert_command(Ordering::ConfirmOrder.new(order_id: order_id))
    end
  end
end
