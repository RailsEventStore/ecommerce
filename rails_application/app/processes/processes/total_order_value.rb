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
      discounted_value = subtotal * (1 - state.discount_amount / 100.0)
      publish_total_order_value(subtotal, discounted_value)
    end

    def apply(event)
      @order_id = event.data.fetch(:order_id)
      case event
      when Pricing::PriceItemAdded
        product_id = event.data.fetch(:product_id)
        lines = (state.lines + [{ product_id:, price: event.data.fetch(:price) }])
        state.with(lines:)
      when Pricing::PriceItemRemoved
        lines = state.lines.reject { |line| line.fetch(:product_id) == event.data.fetch(:product_id) }
        state.with(lines:)
      when Pricing::PercentageDiscountSet
        state.with(discount_amount: event.data.fetch(:amount))
      when Pricing::PercentageDiscountChanged
        state.with(discount_amount: event.data.fetch(:amount))
      when Pricing::PercentageDiscountRemoved
        state.with(discount_amount: 0)
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

  Offer = Data.define(:lines, :discount_amount) do
    def initialize(lines: [], discount_amount: 0)
      super(lines: lines.freeze, discount_amount:)
    end
  end



end