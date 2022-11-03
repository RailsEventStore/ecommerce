module Processes
  class CheckAvailabilityOnOrderItemAddedToBasket
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      product_id = event.data.fetch(:product_id)
      quantity = event.data.fetch(:quantity_before) + 1
      command_bus.call(Inventory::CheckAvailability.new(product_id: product_id, desired_quantity: quantity))
    end

    private

    attr_reader :command_bus
  end
end