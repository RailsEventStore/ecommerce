module Processes
  class TotalOrderValue
    include Infra::ProcessManager.with_state { Offer }

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::PercentageDiscountSet,
      Pricing::PercentageDiscountChanged,
      Pricing::PercentageDiscountRemoved
    )

    private

    def act
      publish_total_order_value(calculate_subtotal, calculate_discounted_value)
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
    private

    def publish_total_order_value(total_amount, discounted_amount)
      event_store.publish(
        TotalOrderValueUpdated.new(data: { 
          total_amount: total_amount, 
          discounted_amount: discounted_amount,
          order_id: @order_id 
        }),
        stream_name: "Processes::TotalOrderValue$#{@order_id}"
      )
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply_price_item_added(event)
      product_id = event.data.fetch(:product_id)
      base_price = event.data.fetch(:base_price)
      lines = (state.lines + [{ product_id:, price: base_price }])
      state.with(lines:)
    end

    def apply_price_item_removed(event)
      lines = state.lines.reject { |line| line.fetch(:product_id) == event.data.fetch(:product_id) }
      state.with(lines:)
    end

    def apply_percentage_discount_set(event)
      discount_type = event.data.fetch(:type)
      discount_amount = event.data.fetch(:amount)
      discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
      discounts = discounts + [{ type: discount_type, amount: discount_amount }]
      state.with(discounts:)
    end

    def apply_percentage_discount_changed(event)
      discount_type = event.data.fetch(:type)
      discount_amount = event.data.fetch(:amount)
      discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
      discounts = discounts + [{ type: discount_type, amount: discount_amount }]
      state.with(discounts:)
    end

    def apply_percentage_discount_removed(event)
      discount_type = event.data.fetch(:type)
      discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
      state.with(discounts:)
    end

    def calculate_subtotal
      state.lines.sum { |line| line.fetch(:price) }
    end

    def calculate_total_discount_percentage
      state.discounts.sum { |discount| discount.fetch(:amount) }
    end

    def calculate_final_discount_percentage
      [calculate_total_discount_percentage, 100].min
    end

    def calculate_discounted_value
      calculate_subtotal * (1 - calculate_final_discount_percentage / 100.0)
    end
  end

  Offer = Data.define(:lines, :discounts) do
    def initialize(lines: [], discounts: [])
      super(lines: lines.freeze, discounts: discounts.freeze)
    end
  end

end