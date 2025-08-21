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
      subtotal = state.lines.sum { |line| line.fetch(:price) }
      
      total_discount = state.discounts.sum { |discount| discount.fetch(:amount) }
      final_discount = [total_discount, 100].min
      
      discounted_value = subtotal * (1 - final_discount / 100.0)
      publish_total_order_value(subtotal, discounted_value)
    end

    def apply(event)
      @order_id = event.data.fetch(:order_id)
      case event
      when Pricing::PriceItemAdded
        product_id = event.data.fetch(:product_id)
        base_price = event.data.fetch(:base_price)
        lines = (state.lines + [{ product_id:, price: base_price }])
        state.with(lines:)
      when Pricing::PriceItemRemoved
        lines = state.lines.reject { |line| line.fetch(:product_id) == event.data.fetch(:product_id) }
        state.with(lines:)
      when Pricing::PercentageDiscountSet
        discount_type = event.data.fetch(:type)
        discount_amount = event.data.fetch(:amount)
        discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
        discounts = discounts + [{ type: discount_type, amount: discount_amount }]
        state.with(discounts:)
      when Pricing::PercentageDiscountChanged
        discount_type = event.data.fetch(:type)
        discount_amount = event.data.fetch(:amount)
        discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
        discounts = discounts + [{ type: discount_type, amount: discount_amount }]
        state.with(discounts:)
      when Pricing::PercentageDiscountRemoved
        discount_type = event.data.fetch(:type)
        discounts = state.discounts.reject { |d| d.fetch(:type) == discount_type }
        state.with(discounts:)
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
  end

  Offer = Data.define(:lines, :discounts) do
    def initialize(lines: [], discounts: [])
      super(lines: lines.freeze, discounts: discounts.freeze)
    end
  end

end