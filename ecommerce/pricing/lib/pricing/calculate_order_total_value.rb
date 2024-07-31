module Pricing
  class CalculateOrderTotalValue
    def call(event)
      command_bus.(CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))
    end

    private

    def command_bus
      Pricing.command_bus
    end
  end
end

