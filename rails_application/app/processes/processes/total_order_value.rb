module Processes
  class TotalOrderValue
    def initialize(event_store)
      @event_store = event_store
      @total_value = 0
    end

    def call(event)
      case event
      when Pricing::PriceItemAdded
        @total_value += event.data.fetch(:price)
        @order_id     = event.data.fetch(:order_id)
      end
      publish_total_order_value
    end

    private

    def publish_total_order_value
      @event_store.publish(
        TotalOrderValueUpdated.new(data: { total_value: @total_value, order_id: @order_id }),
        stream_name: "Processes::TotalOrderValue$#{@order_id}"
      )
    end
  end

end