module Invoicing
  class Invoice
    include AggregateRoot

    def initialize(invoice_id)
      @invoice_id = invoice_id
      @invoice_items = []
    end

    def add_item(product_id, unit_price, vat_rate, quantity)
      apply(
        InvoiceItemAdded.new(
          data: {
            invoice_id: @invoice_id,
            product_id: product_id,
            quantity: quantity,
            unit_price: unit_price,
            vat_rate: vat_rate
          }
        )
      )
    end

    private

    on InvoiceItemAdded do |event|
      @invoice_items << InvoiceItem.new(event.data[:product_id], event.data[:unit_price], event.data[:vat_rate], event.data[:quantity])
    end
  end

  class InvoiceItem
    attr_reader :product_id, :quantity, :unit_price, :vat_rate

    def initialize(product_id, unit_price, vat_rate, quantity)
      @product_id = product_id
      @unit_price = unit_price
      @vat_rate = vat_rate
      @quantity = quantity
    end
  end
end