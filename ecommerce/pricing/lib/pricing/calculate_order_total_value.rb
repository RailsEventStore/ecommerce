module Pricing
  class CalculateOrderTotalValue < Infra::EventHandler
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.(CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))
    end

    private attr_reader :command_bus
  end
end

