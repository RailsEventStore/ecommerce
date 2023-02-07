module Pricing
  class CalculateOrderTotalValue < Infra::EventHandler
    def call(event)
      command_bus.(CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))
    end

    private

    def command_bus
      Pricing.command_bus
    end
  end
end

