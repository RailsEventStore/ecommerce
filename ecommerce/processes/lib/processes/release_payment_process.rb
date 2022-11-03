module Processes
  class ReleasePaymentProcess
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      state = build_state(event)
      release_payment(state) if state.release?
    end

    private

    def release_payment(state)
      command_bus.run(Payments::ReleasePayment.new(order_id: state.order_id))
    end

    attr_reader :command_bus

    def build_state(event)
      stream_name = "PaymentProcess$#{event.data.fetch(:order_id)}"
      past_events = command_bus.all_events_from_stream(stream_name)
      last_stored = past_events.size - 1
      command_bus.link_event_to_stream(event, stream_name, last_stored)
      ProcessState.new.tap do |state|
        past_events.each { |ev| state.call(ev) }
        state.call(event)
      end
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    end

    class ProcessState
      def initialize
        @order = :draft
        @payment = :none
      end

      attr_reader :order_id

      def call(event)
        case event
        when Payments::PaymentAuthorized
          @payment = :authorized
        when Payments::PaymentReleased
          @payment = :released
        when Ordering::OrderSubmitted
          @order = :submitted
          @order_id = event.data.fetch(:order_id)
        when Ordering::OrderExpired
          @order = :expired
        when Ordering::OrderConfirmed
          @order = :confirmed
        end
      end

      def release?
        @payment.eql?(:authorized) && @order.eql?(:expired)
      end
    end
  end
end