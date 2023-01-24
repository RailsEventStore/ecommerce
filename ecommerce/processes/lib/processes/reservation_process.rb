module Processes
  class ReservationProcess
    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(event)
      stream_name = "ReservationProcess$#{event.data.fetch(:order_id)}"
      begin
        past_events = event_store.read.stream(stream_name).to_a
        last_stored = past_events.size - 1
        event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
      rescue RubyEventStore::WrongExpectedEventVersion
        retry
      end
      state = ProcessState.new
      past_events.each { |ev| state.call(ev) }
      previous_state = state.state
      state.call(event)

      case [previous_state, event.event_type]
      when [:not_started, 'Ordering::OrderPreSubmitted']
        reserve_stock(state.order_id, state.order_lines)
      when [:awaiting_reservation, 'Inventory::StockReserved']
        confirm_order(state) if state.all_reserved?
      when [:awaiting_reservation, 'Inventory::StockUnavailable']
        reject_order(state)
        release_stock(state.order_id, state.order_lines.slice(*state.reserved_product_ids))
      when [:awaiting_reservation, 'Ordering::OrderExpired'], [:reserved, 'Ordering::OrderCancelled']
        release_stock(state.order_id, state.order_lines.slice(*state.reserved_product_ids))
      when [:abandoned, 'Inventory::StockReserved']
        release_stock(state.order_id, state.order_lines.slice(event.data.fetch(:product_id)))
      when [:reserved, 'Ordering::OrderConfirmed']
        dispatch_stock(state.order_id, state.order_lines)
      end
    end

    private

    attr_reader :command_bus, :event_store

    def reserve_stock(order_id, order_lines)
      order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Reserve.new(order_id: order_id, product_id: product_id, quantity: quantity))
      end
    end

    def release_stock(order_id, order_lines)
      order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Release.new(order_id: order_id, product_id: product_id, quantity: quantity))
      end
    end

    def dispatch_stock(order_id, order_lines)
      order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Dispatch.new(order_id: order_id, product_id: product_id, quantity: quantity))
      end
    end

    def confirm_order(state)
      command_bus.(Ordering::AcceptOrder.new(order_id: state.order_id))
    end

    def reject_order(state)
      command_bus.(Ordering::RejectOrder.new(order_id: state.order_id))
    end

    class ProcessState
      def initialize
        @reserved_product_ids = []
        @abandon = false
        @state = :not_started
      end

      attr_reader :order_id, :order_lines, :reserved_product_ids, :state

      def call(event)
        case event
        when Ordering::OrderPreSubmitted
          @order_id = event.data.fetch(:order_id)
          @order_lines = event.data.fetch(:order_lines)
          @state = :awaiting_reservation
        when Inventory::StockReserved
          @reserved_product_ids << event.data.fetch(:product_id)
          @state = :reserved if all_reserved?
        when Inventory::StockUnavailable, Ordering::OrderExpired, Ordering::OrderCancelled
          @state = :abandoned
        when Ordering::OrderConfirmed
          @state = :complete
        end
      end

      def all_reserved?
        @order_lines.keys.sort == @reserved_product_ids.sort
      end
    end
  end
end