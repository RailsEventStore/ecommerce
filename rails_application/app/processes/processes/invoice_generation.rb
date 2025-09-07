require_relative 'invoices/money_splitter'

module Processes
  class InvoiceGeneration
    include Infra::ProcessManager.with_state { Invoice }

    def initialize(event_store, command_bus)
      super(event_store, command_bus)
      @vat_rate_catalog = Taxes::VatRateCatalog.new(event_store)
    end

    subscribes_to(
      Processes::TotalOrderValueUpdated,
      Fulfillment::OrderRegistered
    )

    def act
      create_invoice_items_for_all_products if state.placed?
    end

    private

    def create_invoice_items_for_all_products
      state.items.each do |item|
        create_invoice_items_for_product(item.fetch(:product_id), item.fetch(:quantity), item.fetch(:amount))
      end
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
      @order_id = event.data.fetch(:order_id)
      case event
      when TotalOrderValueUpdated
        state.set_items(event.data.fetch(:items))
      when Fulfillment::OrderRegistered
        state.mark_placed
      end
    end

    def create_invoice_items_for_product(product_id, quantity, discounted_amount)
      vat_rate = @vat_rate_catalog.vat_rate_for(product_id)
      unit_prices = Invoices::MoneySplitter.new(discounted_amount, quantity).call
      unit_prices.tally.each do |unit_price, quantity|
        command_bus.call(
          Invoicing::AddInvoiceItem.new(
            invoice_id: @order_id,
            product_id: product_id,
            vat_rate: vat_rate,
            quantity: quantity,
            unit_price: unit_price
          )
        )
      end
    end

  end

  Invoice = Data.define(:items, :order_placed) do
    def initialize(items: [], order_placed: false)
      super(items: items.freeze, order_placed: order_placed)
    end

    def set_items(new_items)
      with(items: new_items)
    end

    def mark_placed
      with(order_placed: true)
    end

    def placed?
      order_placed
    end
  end

end
