module Processes
  class DetermineVatRatesOnOrderSubmitted
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      order_id = event.data.fetch(:order_id)
      event.data.fetch(:order_lines).each do |product_quantity_hash|
        product_id = product_quantity_hash.first
        command = Taxes::DetermineVatRate.new(order_id: order_id, product_id: product_id)
        command_bus.call(command)
      end
    end

    private

    attr_reader :command_bus
  end
end