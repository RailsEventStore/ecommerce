module Processes
  class ThreePlusOneFree

    class ProcessState < Data.define(:lines, :free_product, :should_act)
      def initialize(lines: [], free_product: nil, should_act: nil) = super

      MIN_ORDER_LINES_QUANTITY = 4

      def eligible_free_product_id
        if lines.size >= MIN_ORDER_LINES_QUANTITY
          line = lines.first
          line.fetch(:product_id)
        end
      end

      def current_free_product_id = free_product
    end

    include Infra::ProcessManager.with_state(ProcessState)

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::ProductMadeFreeForOrder,
      Pricing::FreeProductRemovedFromOrder
    )

    private

    def apply(event)
      product_id = event.data.fetch(:product_id)
      case event
      when Pricing::PriceItemAdded
        lines = (state.lines + [{ product_id:, price: event.data.fetch(:price) }]).sort_by { |line| line.fetch(:price) }
        state.with(lines:, should_act: true)
      when Pricing::PriceItemRemoved
        lines = state.lines.dup
        index_of_line_to_remove = lines.index { |line| line.fetch(:product_id) == product_id && line.fetch(:price) == event.data.fetch(:price) }
        lines.delete_at(index_of_line_to_remove)
        state.with(lines: lines, should_act: true)
      when Pricing::ProductMadeFreeForOrder
        state.with(free_product: product_id, should_act: false)
      when Pricing::FreeProductRemovedFromOrder
        state.with(free_product: nil, should_act: false)
      end
    end

    def act
      return if state.current_free_product_id == state.eligible_free_product_id
      return unless !!state.should_act

      remove_old_free_product if state.current_free_product_id
      make_new_product_for_free(state.eligible_free_product_id) if state.eligible_free_product_id
    end

    def remove_old_free_product
      command_bus.call(Pricing::RemoveFreeProductFromOrder.new(order_id: id, product_id: state.current_free_product_id)) if state.current_free_product_id
    end

    def make_new_product_for_free(free_product_id)
      command_bus.call(Pricing::MakeProductFreeForOrder.new(order_id: id, product_id: free_product_id)) if free_product_id
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end
  end
end
