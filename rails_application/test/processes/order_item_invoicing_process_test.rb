require "test_helper"

module Processes
  class OrderItemInvoicingProcessTest < ProcessTest
    cover "Processes::InvoiceGeneration*"

    def setup
      super
      @product_id = SecureRandom.uuid
      @amount = 100.to_d
      @discounted_amount = 90.to_d
      @quantity = 5
      @vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
    end

    def test_invoice_item_being_created
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: @product_id, vat_rate: @vat_rate }))
      
      process = InvoiceGeneration.new(event_store, command_bus)

      # To get the same result as the original test:
      # - Original had: quantity=5, discounted_amount=90, resulting in unit_price=18
      # - We need to create scenario where total discounted amount for this product is 90 across 5 items
      # - So we add 5 items of base price 20 each (100 total), with 10% discount -> 90 total -> 18 per unit
      events = [
        price_item_added(@product_id, 20, 20),
        price_item_added(@product_id, 20, 20),
        price_item_added(@product_id, 20, 20),
        price_item_added(@product_id, 20, 20),
        price_item_added(@product_id, 20, 20),
        percentage_discount_set("discount", 10),
        order_placed
      ]

      events.each do |event|
        event_store.publish(event)
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


    private

    def price_item_added(product_id, base_price = 100, price = 100)
      Pricing::PriceItemAdded.new(data: {
        order_id: order_id,
        product_id: product_id,
        base_price: base_price,
        price: price
      })
    end

    def order_placed
      Fulfillment::OrderRegistered.new(data: {
        order_id: order_id,
        order_number: Fulfillment::FakeNumberGenerator::FAKE_NUMBER
      })
    end

    def percentage_discount_set(type, amount)
      Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: type,
        amount: amount
      })
    end
  end
end
