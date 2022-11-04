require_relative "test_helper"

module Processes
  class OrderItemInvoicingProcessTest < Test
    cover "Processes::OrderItemInvoicingProcess*"

    def test_invoice_item_being_created
      product_id = SecureRandom.uuid
      amount = 100.to_d
      discounted_amount = 90.to_d
      quantity = 5
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")

      item_value_calculated = Pricing::PriceItemValueCalculated.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          quantity: quantity,
          amount: amount,
          discounted_amount: discounted_amount
        }
      )
      vat_rate_determined = Taxes::VatRateDetermined.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          vat_rate: vat_rate
        }
      )
      process = OrderItemInvoicingProcess.new(event_store, command_bus)
      given([item_value_calculated, vat_rate_determined]).each do |event|
        process.call(event)
      end
      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: product_id,
        quantity: quantity,
        vat_rate: vat_rate,
        unit_price: 18.to_d
      ))
    end
  end
end