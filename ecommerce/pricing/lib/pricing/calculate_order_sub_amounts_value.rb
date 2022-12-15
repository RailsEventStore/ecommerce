module Pricing
  class CalculateOrderTotalSubAmountsValue < Infra::EventHandler
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.(CalculateSubAmounts.new(order_id: event.data.fetch(:order_id)))
    end

    attr_reader :command_bus
  end
end

