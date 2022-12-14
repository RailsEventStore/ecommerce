module Pricing
  class ReduceOrderTotalValue < Infra::EventHandler
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.(RemovePriceItem.new(order_id: event.data.fetch(:order_id), product_id: event.data.fetch(:product_id)))
    end

    private attr_reader :command_bus
  end
end
