require "test_helper"

module Processes
  class OrderItemInvoicingProcessTest < ProcessTest
    cover "Processes::InvoiceGeneration*"

    def setup
      super
      @product_id = SecureRandom.uuid
      @quantity = 5
      @vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
    end

    def test_invoice_item_being_created
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: @product_id, vat_rate: @vat_rate }))
      
      process = InvoiceGeneration.new(event_store, command_bus)

      publish_total_value_updated(process, [
        { product_id: @product_id, quantity: @quantity, amount: 90 }
      ])

      event = order_placed
      event_store.publish(event)
      process.call(event)

      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_id,
        quantity: @quantity,
        vat_rate: @vat_rate,
        unit_price: 18.to_d
      ))
    end


    private

    def publish_total_value_updated(process, items)
      event = Processes::TotalOrderValueUpdated.new(data: {
        order_id: order_id,
        total_amount: items.sum { |i| i[:amount] },
        discounted_amount: items.sum { |i| i[:amount] },
        items: items
      })
      event_store.publish(event, stream_name: "Processes::TotalOrderValue$#{order_id}")
      process.call(event)
    end

    def order_placed
      Fulfillment::OrderRegistered.new(data: {
        order_id: order_id,
        order_number: Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      })
    end
  end
end
