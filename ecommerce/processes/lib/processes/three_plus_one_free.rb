require_relative 'state_projectors/three_plus_one_free'

module Processes
  class ThreePlusOneFree
    include Infra::ProcessManager.with_state(StateProjectors::ThreePlusOneFree)

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
  end
end
