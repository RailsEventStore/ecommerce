module Processes
  class ReservationProcess < Infra::EventHandler
    def initialize
      @event_store = Configuration.event_store
      @command_bus = Configuration.command_bus
    end
    attr_accessor :event_store, :command_bus

    def call(event)
      state = build_state(event)
      case event.event_type
      when 'Ordering::OrderPreSubmitted'
        begin
          reserve_stock(state)
        rescue Inventory::InventoryEntry::InventoryNotAvailable
          release_stock(state)
          reject_order(state)
        else
          accept_order(state)
        end
      when 'Ordering::OrderCancelled'
        release_stock(state)
      when 'Ordering::OrderConfirmed'
        dispatch_stock(state)
      end
    end

    private

    def reserve_stock(state)
      state.order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Reserve.new(product_id: product_id, quantity: quantity))
        state.product_reserved(product_id)
      end
    end

    def release_stock(state)
      state.order_lines.slice(*state.reserved_product_ids).each do |product_id, quantity|
        command_bus.(Inventory::Release.new(product_id: product_id, quantity: quantity))
      end
    end

    def dispatch_stock(state)
      state.order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Dispatch.new(product_id: product_id, quantity: quantity))
      end
    end

    def accept_order(state)
      command_bus.(Ordering::AcceptOrder.new(order_id: state.order_id))
    end

    def reject_order(state)
      command_bus.(Ordering::RejectOrder.new(order_id: state.order_id))
    end

    def build_state(event)
      stream_name = "ReservationProcess$#{event.data.fetch(:order_id)}"
      begin
        past_events = event_store.read.stream(stream_name).to_a
        last_stored = past_events.size - 1
        event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
      rescue RubyEventStore::WrongExpectedEventVersion
        retry
      rescue RubyEventStore::EventDuplicatedInStream
        return
      end
      ProcessState.new.tap do |state|
        past_events.each { |ev| state.call(ev) }
        state.call(event)
      end
    end

    class ProcessState
      def initialize()
        @reserved_product_ids = []
      end

      attr_reader :order_id, :order_lines, :reserved_product_ids

      def call(event)
        case event
        when Ordering::OrderPreSubmitted
          @order_lines = event.data.fetch(:order_lines)
          @order_id = event.data.fetch(:order_id)
        when Ordering::OrderCancelled, Ordering::OrderConfirmed
          @reserved_product_ids = order_lines.keys
        end
      end

      def product_reserved(product_id)
        reserved_product_ids << product_id
      end
    end
  end
end