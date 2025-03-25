require_relative "test_helper"

module Processes
  class DetermineVatRateTest < Test
    cover "Processes::DetermineVatRatesOnOrderPlaced*"

    def test_happy_path
      product_id = SecureRandom.uuid
      process = DetermineVatRatesOnOrderPlaced.new(event_store, command_bus)
      given([offer_accepted(order_id, product_id), order_placed]).each do |event|
        process.call(event)
      end
      assert_command(Taxes::DetermineVatRate.new(order_id: order_id, product_id: product_id))
    end

    def test_accepted_but_not_placed
      process = DetermineVatRatesOnOrderPlaced.new(event_store, command_bus)
      given([offer_accepted(order_id, SecureRandom.uuid)]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_placed_but_not_accepted
      process = DetermineVatRatesOnOrderPlaced.new(event_store, command_bus)
      given([order_placed]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    private

    def offer_accepted(order_id, product_id)
      Pricing::OfferAccepted.new(
        data: {
          order_id: order_id,
          order_lines: [{ product_id: product_id, quantity: 1 }]
        }
      )
    end
  end
end
