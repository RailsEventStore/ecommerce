module Processes

  class ProcessManager
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def run(stream_name, new_event, object)
      build_object_from_existing_events(object, stream_name, new_event)
      object.process(new_event)
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    end

    private

    def build_object_from_existing_events(object, stream_name, new_event)
      past_events = @cqrs.all_events_from_stream(stream_name)
      @cqrs.link_event_to_stream(new_event, stream_name, past_events.size - 1)
      object.apply(past_events)
    end
  end

  class OrderConfirmation < ProcessManager
    def call(event)
      process = ProcessState.new(@cqrs)
      run(stream_name(event), event, process)
    end

    private

    def stream_name(event)
      "OrderConfirmation$#{event.data.fetch(:order_id)}"
    end

    class ProcessState
      def initialize(cqrs)
        @cqrs = cqrs
      end

      def process(event)
        @cqrs.run(Ordering::ConfirmOrder.new(order_id: @order_id)) if event.class.equal?(Payments::PaymentCaptured)
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
