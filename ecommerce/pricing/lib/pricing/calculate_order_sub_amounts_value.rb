module Pricing
  class CalculateOrderTotalSubAmountsValue < Infra::EventHandler
    def call(event)
      command_bus.(CalculateSubAmounts.new(order_id: event.data.fetch(:order_id)))
    end
  end
end

