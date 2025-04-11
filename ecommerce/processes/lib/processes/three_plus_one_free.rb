module Processes
  class ThreePlusOneFree
    include Infra::Retry

    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
      @event_store.subscribe(
        self,
        to: [
          Pricing::PriceItemAdded,
          Pricing::PriceItemRemoved,
          Pricing::ProductMadeFreeForOrder,
          Pricing::FreeProductRemovedFromOrder
        ]
      )
    end

    def call(event)
      state = build_state(event)
      return if event_only_for_state_building?(event)

      make_or_remove_free_product(state)
    end

    private

    def build_state(event)
      with_retry do
        stream_name = "ThreePlusOneFreeProcess$#{event.data.fetch(:order_id)}"
        past_events = @event_store.read.stream(stream_name).to_a
        last_stored = past_events.size - 1
        @event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
        ProcessState.new(event.data.fetch(:order_id)).tap do |state|
          past_events.each { |ev| state.call(ev) }
          state.call(event)
        end
      end
    end

    def make_or_remove_free_product(state)
      free_product_id = state.cheapest_product

      return if current_free_product_not_changed?(free_product_id, state)

      remove_old_free_product(state)
      make_new_product_for_free(state, free_product_id)
    end

    def event_only_for_state_building?(event)
      event.instance_of?(Pricing::FreeProductRemovedFromOrder) || event.instance_of?(Pricing::ProductMadeFreeForOrder)
    end

    def current_free_product_not_changed?(free_product_id, state)
      free_product_id == state.current_free_product_id
    end

    def remove_old_free_product(state)
      @command_bus.call(Pricing::RemoveFreeProductFromOrder.new(order_id: state.order_id, product_id: state.current_free_product_id)) if state.current_free_product_id
    end

    def make_new_product_for_free(state, free_product_id)
      @command_bus.call(Pricing::MakeProductFreeForOrder.new(order_id: state.order_id, product_id: free_product_id)) if free_product_id
    end

    class ProcessState
      attr_reader :order_id, :order_lines, :current_free_product_id

      def initialize(order_id)
        @order_id = order_id
        @order_lines = []
      end

      def call(event)
        product_id = event.data.fetch(:product_id)
        case event
        when Pricing::PriceItemAdded
          order_lines << { product_id: event.data.fetch(:product_id), price: event.data.fetch(:price) }
        when Pricing::PriceItemRemoved
          new_lines = order_lines.sort { _1.fetch(:price) }
          index_of_line_to_remove = new_lines.index { |line| line.fetch(:product_id) == product_id }
          new_lines.delete_at(index_of_line_to_remove)
          @order_lines = new_lines
        when Pricing::ProductMadeFreeForOrder
          @current_free_product_id = product_id
        when Pricing::FreeProductRemovedFromOrder
          @current_free_product_id = nil
        end
      end

      def total_quantity
        order_lines.values.sum
      end

      MIN_ORDER_LINES_QUANTITY = 4
      def cheapest_product
        order_lines.sort_by { |line| line.fetch(:price) }.first.fetch(:product_id) if order_lines.size >= MIN_ORDER_LINES_QUANTITY
      end
    end
  end
end
