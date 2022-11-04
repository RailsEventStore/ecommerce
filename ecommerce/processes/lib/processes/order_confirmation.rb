module Processes

  class ProcessManager
    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def run(stream_name, new_event, object)
      build_object_from_existing_events(object, stream_name, new_event)
      object.process(new_event)
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    end

    private

    attr_reader :event_store, :command_bus

    def build_object_from_existing_events(object, stream_name, new_event)
      past_events = event_store.read.stream(stream_name).to_a
      event_store.link(new_event.event_id, stream_name: stream_name, expected_version: past_events.size - 1)
      object.apply(past_events)
    end
  end

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
