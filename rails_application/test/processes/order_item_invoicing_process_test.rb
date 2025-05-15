require "test_helper"

module Processes
  class OrderItemInvoicingProcessTest < ProcessTest
    cover "Processes::OrderItemInvoicingProcess*"

    def setup
      super
      @product_id = SecureRandom.uuid
      @amount = 100.to_d
      @discounted_amount = 90.to_d
      @quantity = 5
      @vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
    end

    def test_invoice_item_being_created
      process = OrderItemInvoicingProcess.new(event_store, command_bus)
      given([
              Pricing::PriceItemValueCalculated.new(
                data: {
                  order_id: order_id,
                  product_id: @product_id,
                  quantity: @quantity,
                  amount: @amount,
                  discounted_amount: @discounted_amount
                }
              ),
              Taxes::VatRateDetermined.new(
                data: {
                  order_id: order_id,
                  product_id: @product_id,
                  vat_rate: @vat_rate
                }
              )]).each do |event|
        process.call(event)
      end
      assert_command(Invoicing::AddInvoiceItem.new(
        invoice_id: order_id,
        product_id: @product_id,
        quantity: @quantity,
        vat_rate: @vat_rate,
        unit_price: 18.to_d
      ))
    end
  end

  def test_vat_rate_comes_first
    process = OrderItemInvoicingProcess.new(event_store, command_bus)
    given([
            Taxes::VatRateDetermined.new(
              data: {
                order_id: order_id,
                product_id: @product_id,
                vat_rate: @vat_rate
              }
            ),
            Pricing::PriceItemValueCalculated.new(
              data: {
                order_id: order_id,
                product_id: @product_id,
                quantity: @quantity,
                amount: @amount,
                discounted_amount: @discounted_amount
              }
            )
          ]).each do |event|
      process.call(event)
    end
    assert_command(Invoicing::AddInvoiceItem.new(
      invoice_id: order_id,
      product_id: @product_id,
      quantity: @quantity,
      vat_rate: @vat_rate,
      unit_price: 18.to_d
    ))
  end

  def test_stream_name
    process = OrderItemInvoicingProcess.new(event_store, command_bus)
    given([Pricing::PriceItemValueCalculated.new(data: { order_id: order_id,
                                                         product_id: product_id,
                                                         quantity: quantity,
                                                         amount: amount,
                                                         discounted_amount: discounted_amount })]).each do |event|
      process.call(event)
    end
    assert_equal "Processes::OrderItemInvoicingProcess$#{order_id}", process.send(:stream_name)
  end
end