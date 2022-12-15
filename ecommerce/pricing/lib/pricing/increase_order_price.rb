module Pricing
  class IncreaseOrderPrice < Infra::EventHandler
    def call(event)
      command_bus.(AddPriceItem.new(order_id: event.data.fetch(:order_id), product_id: event.data.fetch(:product_id)))
    end

    private

    def command_bus
      Pricing.command_bus
    end
  end
end
