require_relative 'invoices/money_splitter'

module Processes
  class InvoiceGeneration
    include Infra::ProcessManager.with_state { Invoice }

    def initialize(event_store, command_bus)
      super(event_store, command_bus)
      @vat_rate_catalog = Taxes::VatRateCatalog.new(event_store)
    end

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::PercentageDiscountSet,
      Pricing::PercentageDiscountChanged,
      Pricing::PercentageDiscountRemoved,
      Fulfillment::OrderRegistered
    )

    def act
      create_invoice_items_for_all_products if state.placed?
    end

    private

    def create_invoice_items_for_all_products
      product_totals.each do |product_id, quantity, amount|
        create_invoice_items_for_product(product_id, quantity, amount)
      end
    end

    def product_totals
      state.sub_amounts_total.map do |product_id, amounts|
        [product_id, amounts.fetch(:quantity), amounts.fetch(:amount)]
      end
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
      @order_id = event.data.fetch(:order_id)
      case event
      when Pricing::PriceItemAdded
        state.add_line(event.data.fetch(:product_id), event.data.fetch(:base_price), event.data.fetch(:price))
      when Pricing::PriceItemRemoved
        state.remove_line(event.data.fetch(:product_id))
      when Pricing::PercentageDiscountSet
        state.set_discount(event.data.fetch(:type), event.data.fetch(:amount))
      when Pricing::PercentageDiscountChanged
        state.set_discount(event.data.fetch(:type), event.data.fetch(:amount))
      when Pricing::PercentageDiscountRemoved
        state.remove_discount(event.data.fetch(:type))
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

  Invoice = Data.define(:lines, :discounts, :order_placed) do
    def initialize(lines: [], discounts: [], order_placed: false)
      super(lines: lines.freeze, discounts: discounts.freeze, order_placed: order_placed)
    end

    def add_line(product_id, base_price, price)
      with(lines: lines + [{ product_id:, base_price:, price: }])
    end

    def remove_line(product_id)
      with(lines: lines.dup.tap { |lines| lines.delete_at(index_of_first_line_with(product_id)) })
    end

    def index_of_first_line_with(product_id)
      lines.find_index { |line| line.fetch(:product_id) == product_id }
    end

    def set_discount(type, amount)
      with_discounts_applied(discounts.reject { |d| d.fetch(:type) == type } + [{ type:, amount: }])
    end

    def remove_discount(type)
      with_discounts_applied(discounts.reject { |d| d.fetch(:type) == type })
    end

    def mark_placed
      with(order_placed: true)
    end

    def placed?
      order_placed
    end

    def apply_discounts_to_lines
      with(lines: lines.map { |line| apply_discount_to_line(line) })
    end

    def apply_discount_to_line(line)
      line.merge(price: line.fetch(:base_price) * discount_multiplier)
    end

    def discount_multiplier
      1 - (final_discount_percentage / 100.0)
    end

    def sub_amounts_total
      lines.each_with_object({}) do |line, memo|
        product_id = line.fetch(:product_id)
        memo[product_id] ||= { base_amount: 0, amount: 0, quantity: 0 }
        memo[product_id][:base_amount] += line.fetch(:base_price)
        memo[product_id][:amount] += line.fetch(:price)
        memo[product_id][:quantity] += 1
      end
    end

    private

    def with_discounts_applied(new_discounts)
      with(discounts: new_discounts).apply_discounts_to_lines
    end

    def subtotal
      lines.sum { |line| line.fetch(:price) }
    end

    def total_discount_percentage
      discounts.sum { |discount| discount.fetch(:amount) }
    end

    def final_discount_percentage
      [total_discount_percentage, 100].min
    end

    def discounted_value
      subtotal * (1 - final_discount_percentage / 100.0)
    end
  end

end
