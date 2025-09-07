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
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 20 },
        { product_id: @product_2_id, quantity: 2, amount: 60 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

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
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 18 },
        { product_id: @product_2_id, quantity: 2, amount: 54 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

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
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 0 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 0.to_d
      ))
    end

    def test_calculates_sub_amounts_with_multiple_discounts
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 75 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 75.to_d
      ))
    end

    def test_calculates_sub_amounts_after_item_removal
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 20 },
        { product_id: @product_2_id, quantity: 1, amount: 30 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

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
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 80 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 80.to_d
      ))
    end

    def test_calculates_sub_amounts_with_discount_removed
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 100 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 100.to_d
      ))
    end

    def test_calculates_sub_amounts_with_over_100_percent_discount
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 0 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 0.to_d
      ))
    end

    def test_calculates_sub_amounts_with_discount_type_replacement
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 50 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 50.to_d
      ))
    end

    def test_discount_removal_preserves_other_discounts
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 80 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 80.to_d
      ))
    end

    def test_discount_set_replaces_existing_discount_type
      publish_total_value_updated([
        { product_id: @product_1_id, quantity: 1, amount: 75 }
      ])
      event = order_placed
      event_store.publish(event)
      @process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_1_id,
        quantity: 1,
        vat_rate: @vat_rate,
        unit_price: 75.to_d
      ))
    end

    private

    def publish_total_value_updated(items)
      event = Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id,
        total_amount: items.sum { |i| i[:amount] },
        discounted_amount: items.sum { |i| i[:amount] },
        items: items
      })
      event_store.publish(event, stream_name: "Processes::TotalOrderValue$#{order_id}")
      @process.call(event)
    end

    def order_placed
      Fulfillment::OrderRegistered.new(data: {
        order_id: order_id,
        order_number: Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      })
    end

  end
end
