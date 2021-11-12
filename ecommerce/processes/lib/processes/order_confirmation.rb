module Processes
  class OrderConfirmation
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call(event)
      state = build_state(event)
      if state.confirm_order?
        cqrs.run(Ordering::MarkOrderAsPaid.new(order_id: state.order_id))
      end
    end

    private

    attr_reader :cqrs

    def build_state(event)
      stream_name = "OrderConfirmation$#{event.data.fetch(:order_id)}"
      past = cqrs.all_events_from_stream(stream_name)
      last_stored = past.size - 1
      cqrs.link_event_to_stream(event, stream_name, last_stored)
      ProcessState.new.tap do |state|
        past.each { |ev| state.call(ev) }
        state.call(event)
      end
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    end

    class ProcessState
      def initialize
        @order_id = nil
        @payment = nil
      end

      attr_reader :order_id

      def call(event)
        case event
        when Payments::PaymentAuthorized
          @payment = :authorized
          @order_id = event.data.fetch(:order_id)
        when Payments::PaymentCaptured
          @payment = :captured
        end
      end

      def confirm_order?
        @payment == :captured
      end
    end
  end
end
