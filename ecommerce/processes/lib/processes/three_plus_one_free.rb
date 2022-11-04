module Processes
  class ThreePlusOneFree

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
      stream_name = "ThreePlusOneFreeProcess$#{event.data.fetch(:order_id)}"
      past_events = @event_store.read.stream(stream_name).to_a
      last_stored = past_events.size - 1
      @event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
      ProcessState.new(event.data.fetch(:order_id)).tap do |state|
        past_events.each { |ev| state.call(ev) }
        state.call(event)
      end
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    end

    def make_or_remove_free_product(state)
      pricing_catalog = Pricing::PricingCatalog.new(@event_store)
      free_product_id = FreeProductResolver.new(state, pricing_catalog).call

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
        @order_lines = Hash.new(0)
      end

      def call(event)
        product_id = event.data.fetch(:product_id)
        case event
        when Pricing::PriceItemAdded
          order_lines[product_id] += 1
        when Pricing::PriceItemRemoved
          order_lines[product_id] -= 1
          order_lines.delete(product_id) if order_lines.fetch(product_id) <= 0
        when Pricing::ProductMadeFreeForOrder
          @current_free_product_id = product_id
        when Pricing::FreeProductRemovedFromOrder
          @current_free_product_id = nil
        end
      end

      def total_quantity
        order_lines.values.sum
      end
    end

    class FreeProductResolver
      MIN_ORDER_LINES_QUANTITY = 4

      def initialize(state, pricing_catalog)
        @state = state
        @pricing_catalog = pricing_catalog
      end

      def call
        cheapest_product if eligible_for_free_product?
      end

      private

      attr_reader :state, :pricing_catalog

      def cheapest_product
        state.order_lines.keys.sort_by { |product_id| pricing_catalog.price_by_product_id(product_id) }.first
      end

      def eligible_for_free_product?
        state.total_quantity >= MIN_ORDER_LINES_QUANTITY
      end
    end
  end
end
