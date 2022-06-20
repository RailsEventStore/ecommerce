module Processes
  class ThreePlusOneFree
    MIN_ORDER_LINES_QUANTITY = 4

    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call(event)
      state = build_state(event)
      make_product_free(state) if order_eligible_for_free_product?(state)
    end

    private

    def build_state(event)
      stream_name = "ThreePlusOneFreeProcess$#{event.data.fetch(:order_id)}"
      past_events = @cqrs.all_events_from_stream(stream_name)
      last_stored = past_events.size - 1
      @cqrs.link_event_to_stream(event, stream_name, last_stored)
      ProcessState.new(event.data.fetch(:order_id)).tap do |state|
        past_events.each { |ev| state.call(ev) }
        state.call(event)
      end
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    end

    def make_product_free(state)
      pricing_catalog = Pricing::PricingCatalog.new(@cqrs.event_store)
      free_product_id = FreeProductResolver.new(state.order_lines, pricing_catalog).call

      @cqrs.run(Pricing::MakeProductFreeForOrder.new(order_id: state.order_id, product_id: free_product_id))
    end

    def order_eligible_for_free_product?(state)
      state.total_quantity >= MIN_ORDER_LINES_QUANTITY
    end

    class ProcessState
      attr_reader :order_id, :current_free_product

      def initialize(order_id)
        @order_id = order_id
        @basket = Ordering::Order::Basket.new
      end

      def call(event)
        case event
        when Ordering::ItemAddedToBasket
          @basket.increase_quantity(event.data.fetch(:product_id))
        when Ordering::RemoveItemFromBasket
          @basket.decrease_quantity(event.data.fetch(:product_id))
        end
      end

      def order_lines
        @basket.order_lines
      end

      def total_quantity
        order_lines.values.sum
      end
    end

    class FreeProductResolver
      def initialize(order_lines, pricing_catalog)
        @order_lines = order_lines
        @pricing_catalog = pricing_catalog
      end

      def call
        cheapest_product
      end

      private

      attr_reader :order_lines, :pricing_catalog

      def cheapest_product
        order_lines.keys.sort_by { |product_id| pricing_catalog.price_for(product_id) }.first
      end
    end
  end
end
