require "test_helper"

module Processes
  class InvoiceGenerationTest < ProcessTest
    cover "Processes::InvoiceGeneration"

    def setup
      super

      @vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      @product_1_id = SecureRandom.uuid
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: @product_1_id, vat_rate: @vat_rate }))
      @product_2_id = SecureRandom.uuid
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: @product_2_id, vat_rate: @vat_rate }))

      @process = InvoiceGeneration.new(event_store, command_bus)
    end

    def test_calculates_sub_amounts
      events = [
        price_item_added(@product_1_id, 20, 20),
        price_item_added(@product_2_id, 30, 30),
        price_item_added(@product_2_id, 30, 30),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      expected_commands = [
        Invoicing::AddInvoiceItem.new(
          invoice_id: order_id,
          product_id: @product_1_id,
          quantity: 1,
          vat_rate: @vat_rate,
          unit_price: 20.to_d
        ),
        Invoicing::AddInvoiceItem.new(
          invoice_id: order_id,
          product_id: @product_2_id,
          quantity: 2,
          vat_rate: @vat_rate,
          unit_price: 30.to_d
        )
      ]
      
      actual_commands = @command_bus.all_received.sort_by(&:product_id)
      expected_commands_sorted = expected_commands.sort_by(&:product_id)
      
      assert_equal(expected_commands_sorted, actual_commands)
    end

    def test_calculates_sub_amounts_with_discount
      events = [
        price_item_added(@product_1_id, 20, 20),
        price_item_added(@product_2_id, 30, 30),
        price_item_added(@product_2_id, 30, 30),
        percentage_discount_set("general_discount", 10),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      expected_commands = [
        Invoicing::AddInvoiceItem.new(
          invoice_id: order_id,
          product_id: @product_1_id,
          quantity: 1,
          vat_rate: @vat_rate,
          unit_price: 18.to_d
        ),
        Invoicing::AddInvoiceItem.new(
          invoice_id: order_id,
          product_id: @product_2_id,
          quantity: 2,
          vat_rate: @vat_rate,
          unit_price: 27.to_d
        )
      ]
      
      actual_commands = @command_bus.all_received.sort_by(&:product_id)
      expected_commands_sorted = expected_commands.sort_by(&:product_id)
      
      assert_equal(expected_commands_sorted, actual_commands)
    end

    def test_calculates_sub_amounts_with_100_percent_discount
      events = [
        price_item_added(@product_1_id, 20, 20),
        percentage_discount_set("general_discount", 100),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 0.to_d
      ))
    end

    def test_calculates_sub_amounts_with_multiple_discounts
      events = [
        price_item_added(@product_1_id, 100, 100),
        percentage_discount_set("general_discount", 10),
        percentage_discount_set("time_promotion", 15),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 75.to_d
      ))
    end

    def test_calculates_sub_amounts_after_item_removal
      events = [
        price_item_added(@product_1_id, 20, 20),
        price_item_added(@product_2_id, 30, 30),
        price_item_added(@product_2_id, 30, 30),
        price_item_removed(@product_2_id, 30),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      expected_commands = [
        Invoicing::AddInvoiceItem.new(
          invoice_id: order_id,
          product_id: @product_1_id,
          quantity: 1,
          vat_rate: @vat_rate,
          unit_price: 20.to_d
        ),
        Invoicing::AddInvoiceItem.new(
          invoice_id: order_id,
          product_id: @product_2_id,
          quantity: 1,
          vat_rate: @vat_rate,
          unit_price: 30.to_d
        )
      ]
      
      actual_commands = @command_bus.all_received.sort_by(&:product_id)
      expected_commands_sorted = expected_commands.sort_by(&:product_id)
      
      assert_equal(expected_commands_sorted, actual_commands)
    end

    def test_calculates_sub_amounts_with_discount_changed
      events = [
        price_item_added(@product_1_id, 100, 100),
        percentage_discount_set("general_discount", 10),
        percentage_discount_changed("general_discount", 20),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 80.to_d
      ))
    end

    def test_calculates_sub_amounts_with_discount_removed
      events = [
        price_item_added(@product_1_id, 100, 100),
        percentage_discount_set("general_discount", 10),
        percentage_discount_removed("general_discount"),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 100.to_d
      ))
    end

    def test_calculates_sub_amounts_with_over_100_percent_discount
      events = [
        price_item_added(@product_1_id, 100, 100),
        percentage_discount_set("general_discount", 60),
        percentage_discount_set("time_promotion", 50),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 0.to_d
      ))
    end

    def test_calculates_sub_amounts_with_discount_type_replacement
      events = [
        price_item_added(@product_1_id, 100, 100),
        percentage_discount_set("general_discount", 10),
        percentage_discount_set("time_promotion", 20),
        percentage_discount_changed("general_discount", 30),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 50.to_d
      ))
    end

    def test_discount_removal_preserves_other_discounts
      events = [
        price_item_added(@product_1_id, 100, 100),
        percentage_discount_set("general_discount", 10),
        percentage_discount_set("time_promotion", 20),
        percentage_discount_removed("general_discount"),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 80.to_d
      ))
    end

    def test_discount_set_replaces_existing_discount_type
      events = [
        price_item_added(@product_1_id, 100, 100),
        percentage_discount_set("general_discount", 10),
        percentage_discount_set("general_discount", 25),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
        @process.call(event)
      end

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 75.to_d
      ))
    end

    private

    def price_item_added(product_id = SecureRandom.uuid, base_price = 100, price = 100)
      Pricing::PriceItemAdded.new(data: {
        order_id: order_id,
        product_id: product_id,
        base_price: base_price,
        price: price
      })
    end

    def price_item_removed(product_id, price)
      Pricing::PriceItemRemoved.new(data: {
        order_id: order_id,
        product_id: product_id,
        base_price: price,
        price: price
      })
    end

    def percentage_discount_set(type, amount)
      Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: type,
        amount: amount
      })
    end

    def percentage_discount_changed(type, amount)
      Pricing::PercentageDiscountChanged.new(data: {
        order_id: order_id,
        type: type,
        amount: amount
      })
    end

    def percentage_discount_removed(type)
      Pricing::PercentageDiscountRemoved.new(data: {
        order_id: order_id,
        type: type
      })
    end

    def order_placed
      Fulfillment::OrderRegistered.new(data: {
        order_id: order_id,
        order_number: Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      })
    end

  end
end
