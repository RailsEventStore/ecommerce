module Processes
  class ThreePlusOneFree
    include Infra::ProcessManager.with_state { StateProjector }

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::ProductMadeFreeForOrder,
      Pricing::FreeProductRemovedFromOrder
    )

    private

    def act
      case [state.free_product, state.eligible_free_product]
      in [the_same_product, ^the_same_product]
      in [nil, new_free_product]
        make_new_product_for_free(new_free_product)
      in [old_free_product, *]
        remove_old_free_product(old_free_product)
      else
      end
    end

    def remove_old_free_product(product_id)
      command_bus.call(Pricing::RemoveFreeProductFromOrder.new(order_id: id, product_id:))
    end

    def make_new_product_for_free(product_id)
      command_bus.call(Pricing::MakeProductFreeForOrder.new(order_id: id, product_id:))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    class StateProjector
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
