require "test_helper"

module Processes
  class DetermineVatRateTest < ProcessTest
    cover "Processes::InvoiceGeneration*"

    def test_happy_path
      product_id = SecureRandom.uuid
      process = InvoiceGeneration.new(event_store, command_bus)
      given([price_item_added(order_id, product_id), order_placed]).each do |event|
        process.call(event)
      end
      assert_command(Taxes::DetermineVatRate.new(order_id: order_id, product_id: product_id))
    end

    def test_price_added_but_not_placed
      process = InvoiceGeneration.new(event_store, command_bus)
      given([price_item_added(order_id, SecureRandom.uuid)]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_placed_but_not_accepted
      process = InvoiceGeneration.new(event_store, command_bus)
      given([order_placed]).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_stream_name
      process = InvoiceGeneration.new(event_store, command_bus)
      given([order_placed]).each do |event|
        process.call(event)
      end
      assert_equal "Processes::InvoiceGeneration$#{order_id}", process.send(:stream_name)
    end

    private

    def command_bus
      @command_bus
    end

    def price_item_added(order_id, product_id)
      Pricing::PriceItemAdded.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          base_price: 100,
          price: 100
        }
      )
    end
  end
end
