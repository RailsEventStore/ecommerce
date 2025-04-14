module Processes
  class ThreePlusOneFree

    class ProcessState < Data.define(:lines, :free_product, :eligible_free_product)
      def initialize(lines: [], free_product: nil, eligible_free_product: nil) = super
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
        state.with(lines:, eligible_free_product: eligible_free_product(lines))
      when Pricing::PriceItemRemoved
        lines = state.lines
        index_of_line_to_remove = lines.index { |line| line.fetch(:product_id) == product_id && line.fetch(:price) == event.data.fetch(:price) }
        lines.delete_at(index_of_line_to_remove)
        state.with(lines:, eligible_free_product: eligible_free_product(lines))
      when Pricing::ProductMadeFreeForOrder
        state.with(free_product: product_id, eligible_free_product: eligible_free_product(state.lines))
      when Pricing::FreeProductRemovedFromOrder
        state.with(free_product: nil, eligible_free_product: nil)
      end
    end

    def act
      return if state.free_product == state.eligible_free_product

      remove_old_free_product if state.free_product
      make_new_product_for_free(state.eligible_free_product) if state.eligible_free_product
    end

    def remove_old_free_product
      command_bus.call(Pricing::RemoveFreeProductFromOrder.new(order_id: id, product_id: state.free_product))
    end

    def make_new_product_for_free(product_id)
      command_bus.call(Pricing::MakeProductFreeForOrder.new(order_id: id, product_id: product_id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    MIN_ORDER_LINES_QUANTITY = 4

    def eligible_free_product(lines)
      if lines.size >= MIN_ORDER_LINES_QUANTITY
        line = lines.first
        line.fetch(:product_id)
      end
    end
  end
end
