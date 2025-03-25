module Processes
  class DetermineVatRatesOnOrderPlaced
    include Infra::Retry

    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(event)
      state = build_state(event)
      determine_vat_rates(state) if state.placed?
    end

    def determine_vat_rates(state)
      state.order_lines.each do |line|
        product_id = line.fetch(:product_id)
        command = Taxes::DetermineVatRate.new(order_id: state.order_id, product_id: product_id)
        command_bus.call(command)
      end
    end

    private

    attr_reader :event_store, :command_bus

    def build_state(event)
      with_retry do
        stream_name = "DetermineVatRatesOnOrderPlacedProcess#{event.data.fetch(:order_id)}"
        past_events = event_store.read.stream(stream_name).to_a
        last_stored = past_events.size - 1
        event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
        ProcessState.new.tap do |state|
          past_events.each { |ev| state.call(ev) }
          state.call(event)
        end
      end
    end

    class ProcessState
      def initialize
        @offer_accepted = false
        @order_placed = false
      end

      attr_reader :order_id, :order_lines

      def call(event)
        case event
        when Pricing::OfferAccepted
          @offer_accepted = true
          @order_lines = event.data.fetch(:order_lines)
          @order_id = event.data.fetch(:order_id)
        when Fulfillment::OrderRegistered
          @order_placed = true
        end
      end

      def placed? = @offer_accepted && @order_placed
    end
  end
end
