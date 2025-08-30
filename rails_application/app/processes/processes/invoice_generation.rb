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
      calculate_sub_amounts
    end

    private

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
      @order_id = event.data.fetch(:order_id)
      case event
      when Pricing::PriceItemAdded
        apply_price_item_added(event.data.fetch(:product_id), event.data.fetch(:base_price), event.data.fetch(:price))
      when Pricing::PriceItemRemoved
        apply_price_item_removed(event.data.fetch(:product_id))
      when Pricing::PercentageDiscountSet
        apply_percentage_discount_set(event.data.fetch(:type), event.data.fetch(:amount))
      when Pricing::PercentageDiscountChanged
        apply_percentage_discount_changed(event.data.fetch(:type), event.data.fetch(:amount))
      when Pricing::PercentageDiscountRemoved
        apply_percentage_discount_removed(event.data.fetch(:type))
      when Fulfillment::OrderRegistered
        apply_order_registered
      end
    end

    def calculate_sub_amounts
      return unless state.placed?
      
      sub_amounts_total = state.sub_amounts_total
      sub_amounts_total.each_pair do |product_id, h|
        create_invoice_items_for_product(
          product_id,
          h.fetch(:quantity),
          h.fetch(:amount)
        )
      end
    end

    def create_invoice_items_for_product(product_id, quantity, discounted_amount)
      vat_rate = @vat_rate_catalog.vat_rate_for(product_id)
      unit_prices = MoneySplitter.new(discounted_amount, quantity).call
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

    def apply_price_item_added(product_id, base_price, price)
      state.add_line(product_id, base_price, price)
    end

    def apply_price_item_removed(product_id)
      state.remove_line(product_id)
    end

    def apply_percentage_discount_set(discount_type, discount_amount)
      state.set_discount(discount_type, discount_amount)
    end

    def apply_percentage_discount_changed(discount_type, discount_amount)
      state.set_discount(discount_type, discount_amount)
    end

    def apply_percentage_discount_removed(discount_type)
      state.remove_discount(discount_type)
    end

    def apply_order_registered
      state.mark_placed
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
      total_discount_percentage = self.total_discount_percentage
      final_discount_percentage = [total_discount_percentage, 100].min
      discount_multiplier = (1 - final_discount_percentage / 100.0)
      
      updated_lines = lines.map do |line|
        base_price = line.fetch(:base_price)
        discounted_price = base_price * discount_multiplier
        line.merge(price: discounted_price)
      end
      
      with(lines: updated_lines)
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

  class MoneySplitter
    def initialize(amount, quantity)
      @amount = amount
      @weights = Array.new(quantity, 1)
    end

    def call
      distributed_amounts = []
      total_weight = @weights.sum.to_d
      @weights.each do |weight|
        if total_weight.eql?(0)
          distributed_amounts << 0
          next
        end

        p = weight / total_weight
        distributed_amount = (p * @amount).round(2)
        distributed_amounts << distributed_amount
        total_weight -= weight
        @amount -= distributed_amount
      end

      distributed_amounts
    end
  end

end
