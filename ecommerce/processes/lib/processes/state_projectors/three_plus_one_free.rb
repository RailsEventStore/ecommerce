module Processes
  module StateProjectors
    class ThreePlusOneFree
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

      def self.initial_state_instance
        ProcessState.new
      end

      def self.apply(state_instance, event)
        product_id = event.data.fetch(:product_id)
        case event
        when Pricing::PriceItemAdded
          lines = (state_instance.lines + [{ product_id:, price: event.data.fetch(:price) }])
          state_instance.with(lines:)
        when Pricing::PriceItemRemoved
          lines = state_instance.lines.dup
          index_of_line_to_remove = lines.index { |line| line.fetch(:product_id) == product_id }
          lines.delete_at(index_of_line_to_remove)
          state_instance.with(lines:)
        when Pricing::ProductMadeFreeForOrder
          state_instance.with(free_product: product_id)
        when Pricing::FreeProductRemovedFromOrder
          state_instance.with(free_product: nil)
        end
      end
    end
  end
end
