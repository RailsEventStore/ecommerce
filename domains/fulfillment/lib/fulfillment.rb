require "infra"
require_relative "fulfillment/events/order_registered"
require_relative "fulfillment/events/order_confirmed"
require_relative "fulfillment/events/order_cancelled"
require_relative "fulfillment/commands/register_order"
require_relative "fulfillment/commands/confirm_order"
require_relative "fulfillment/commands/cancel_order"
require_relative "fulfillment/on_register_order"
require_relative "fulfillment/on_cancel_order"
require_relative "fulfillment/on_confirm_order"
require_relative "fulfillment/order"
require_relative "fulfillment/number_generator"
require_relative "fulfillment/fake_number_generator"

module Fulfillment
  class Configuration
    def initialize(number_generator)
      @number_generator = number_generator
    end

    def call(event_store, command_bus)
      command_bus.register(RegisterOrder, OnRegisterOrder.new(event_store, @number_generator.call))
      command_bus.register(ConfirmOrder, OnConfirmOrder.new(event_store))
      command_bus.register(CancelOrder, OnCancelOrder.new(event_store))
    end
  end
end
