module Processes
  class InvoiceGeneration
    include Infra::ProcessManager.with_state { Invoice }

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::PercentageDiscountSet,
      Pricing::PercentageDiscountChanged,
      Pricing::PercentageDiscountRemoved
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
        apply_price_item_added(event)
      when Pricing::PriceItemRemoved
        apply_price_item_removed(event)
      when Pricing::PercentageDiscountSet
        apply_percentage_discount_set(event)
      when Pricing::PercentageDiscountChanged
        apply_percentage_discount_changed(event)
      when Pricing::PercentageDiscountRemoved
        apply_percentage_discount_removed(event)
      else
        state
      end
    end

    def calculate_sub_amounts
      sub_amounts_total = state.sub_amounts_total

      sub_amounts_total.each_pair do |product_id, h|
        publish_invoice_item_value_calculated(
          product_id: product_id,
          quantity: h.fetch(:quantity),
          amount: h.fetch(:base_amount),
          discounted_amount: h.fetch(:amount)
        )
      end
    end

    def publish_invoice_item_value_calculated(product_id:, quantity:, amount:, discounted_amount:)
      event_store.publish(
        InvoiceItemValueCalculated.new(
          data: {
            order_id: @order_id,
            product_id: product_id,
            quantity: quantity,
            amount: amount,
            discounted_amount: discounted_amount
          }
        ),
        stream_name: "Processes::InvoiceGeneration$#{@order_id}"
      )
    end

    def apply_price_item_added(event)
      product_id = event.data.fetch(:product_id)
      base_price = event.data.fetch(:base_price)
      price = event.data.fetch(:price)
      lines = (state.lines + [{ product_id:, base_price:, price: }])
      state.with(lines:)
    end

    def apply_price_item_removed(event)
      product_id = event.data.fetch(:product_id)
      lines = state.lines.dup
      index_to_remove = lines.find_index { |line| line.fetch(:product_id) == product_id}
      lines.delete_at(index_to_remove)
      state.with(lines:)
    end

    def apply_percentage_discount_set(event)
      discount_type = event.data.fetch(:type)
      discount_amount = event.data.fetch(:amount)
      discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
      discounts = discounts + [{ type: discount_type, amount: discount_amount }]
      new_state = state.with(discounts:)
      apply_discounts_to_existing_lines(new_state)
    end

    def apply_percentage_discount_changed(event)
      discount_type = event.data.fetch(:type)
      discount_amount = event.data.fetch(:amount)
      discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
      discounts = discounts + [{ amount: discount_amount }]
      new_state = state.with(discounts: discounts)
      apply_discounts_to_existing_lines(new_state)
    end

    def apply_percentage_discount_removed(event)
      discount_type = event.data.fetch(:type)
      discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
      new_state = state.with(discounts:)
      apply_discounts_to_existing_lines(new_state)
    end

    def apply_discounts_to_existing_lines(new_state)
      total_discount_percentage = new_state.total_discount_percentage
      final_discount_percentage = [total_discount_percentage, 100].min
      discount_multiplier = (1 - final_discount_percentage / 100.0)
      
      updated_lines = new_state.lines.map do |line|
        base_price = line.fetch(:base_price)
        discounted_price = base_price * discount_multiplier
        line.merge(price: discounted_price)
      end
      
      new_state.with(lines: updated_lines)
    end

  end

  Invoice = Data.define(:lines, :discounts) do
    def initialize(lines: [], discounts: [])
      super(lines: lines.freeze, discounts: discounts.freeze)
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
