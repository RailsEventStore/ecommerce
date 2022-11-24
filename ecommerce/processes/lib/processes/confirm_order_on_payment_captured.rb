module Processes
  class ConfirmOrderOnPaymentCaptured

    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      order_id = event.data.fetch(:order_id)
      command_bus.call(Ordering::ConfirmOrder.new(order_id: order_id))
    end

    private
    attr_reader :command_bus
  end
end
