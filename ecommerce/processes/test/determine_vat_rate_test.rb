require_relative "test_helper"

module Processes
  class DetermineVatRateTest < Test
    cover "Processes::DetermineVatRatesOnOrderPlaced*"

    def test_inventory_available_error_is_raised
      skip
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = DetermineVatRatesOnOrderPlaced.new(command_bus)
      given([order_placed(order_id, product_id)]).each do |event|
        process.call(event)
      end
      assert_command(Taxes::DetermineVatRate.new(order_id: order_id, product_id: product_id))
    end

    private

    def order_placed order_id, product_id
      Ordering::OrderPlaced.new(
        data: {
          order_id: order_id,
          order_number: order_number,
          customer_id: customer_id,
          order_lines: { product_id => 1 }
        }
      )
    end
  end
end
