module Processes
  class OrderConfirmation < ProcessManager
    def call(event)
      process = ProcessState.new(command_bus)
      run(stream_name(event), event, process)
    end

    private

    def stream_name(event)
      "OrderConfirmation$#{event.data.fetch(:order_id)}"
    end

    class ProcessState
      def initialize(command_bus)
        @command_bus = command_bus
      end

      def process(event)
        @command_bus.call(Ordering::ConfirmOrder.new(order_id: @order_id)) if event.class.equal?(Payments::PaymentCaptured)
      end

      def apply(events)
        events.each { |event| call(event) }
      end

      def call(event)
        case event
        when Payments::PaymentAuthorized
          @order_id = event.data.fetch(:order_id)
        end
      end
    end
  end
end
