module Processes
  class TotalOrderValue
    include Infra::ProcessManager.with_state { Offer }

    subscribes_to(
      Pricing::PriceItemAdded
    )

    private

    def act
      @total_value = state.lines.sum { |line| line.fetch(:price) }
      publish_total_order_value
    end

    def apply(event)
      @order_id = event.data.fetch(:order_id)
      case event
      when Pricing::PriceItemAdded
        lines = (state.lines + [{ price: event.data.fetch(:price) }])
        state.with(lines:)
      else
        state
      end
    end

    private

    def publish_total_order_value
      event_store.publish(
        TotalOrderValueUpdated.new(data: { total_value: @total_value, order_id: @order_id }),
        stream_name: "Processes::TotalOrderValue$#{@order_id}"
      )
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end
  end

  Offer = Data.define(:lines) do
    def initialize(lines: [])
      super(lines: lines.freeze)
    end
  end



end