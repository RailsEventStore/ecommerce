module Pricing
  class IncreaseOrderPrice < Infra::EventHandler
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.(AddPriceItem.new(order_id: event.data.fetch(:order_id), product_id: event.data.fetch(:product_id)))
    end

    attr_reader :command_bus
  end
end
