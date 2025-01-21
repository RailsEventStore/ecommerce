module Ordering
  class RefundableProducts
    class << self
      def call(order_id)
        RubyEventStore::Projection
          .from_stream("Ordering::Order$#{order_id}")
          .init(-> { [] })
          .when(ItemAddedToBasket, -> (state, event) { increase_quantity(state, event.data.fetch(:product_id)) })
          .when(ItemRemovedFromBasket, -> (state, event) { decrease_quantity(state, event.data.fetch(:product_id)) })
      end

      private

      def increase_quantity(state, product_id)
        prod_quantity = state.find { |prod_quantity| prod_quantity.fetch(:product_id) == product_id }

        if prod_quantity
          prod_quantity[:quantity] += 1
        else
          state << { product_id: product_id, quantity: 1 }
        end
      end

      def decrease_quantity(state, product_id)
        prod_quantity = state.find { |prod_quantity| prod_quantity.fetch(:product_id) == product_id }

        prod_quantity[:quantity] -= 1
        state.delete(prod_quantity) if prod_quantity.fetch(:quantity).zero?
      end
    end
  end
end
