module Pricing
  class CalculateOrderTotalValue < Infra::EventHandler
    def call(event, command_bus)
      command_bus.(CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))
    end

  end
end

