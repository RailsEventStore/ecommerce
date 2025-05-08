module Processes
  class ThreePlusOneFreeStateRepository
    include Infra::ProcessRepository

    ProcessState = Data.define(:lines, :free_product) do
      def initialize(lines: [], free_product: nil)
        super(lines: lines.freeze, free_product:)
      end

      MIN_ORDER_LINES_QUANTITY = 4

      def eligible_free_product
        if lines.size >= MIN_ORDER_LINES_QUANTITY
          lines.sort_by { _1.fetch(:price) }.first.fetch(:product_id)
        end
      end
    end

    apply_event do |current_state, event|
      product_id = event.data.fetch(:product_id)
      case event
      when Pricing::PriceItemAdded
        lines = (current_state.lines + [{ product_id:, price: event.data.fetch(:price) }])
        current_state.with(lines:)
      when Pricing::PriceItemRemoved
        lines = current_state.lines.dup
        index_of_line_to_remove = lines.index { |line| line.fetch(:product_id) == product_id }
        lines.delete_at(index_of_line_to_remove)
        current_state.with(lines:)
      when Pricing::ProductMadeFreeForOrder
        current_state.with(free_product: product_id)
      when Pricing::FreeProductRemovedFromOrder
        current_state.with(free_product: nil)
      end
    end
  end
end