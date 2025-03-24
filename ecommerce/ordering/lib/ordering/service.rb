module Ordering
  class OnCreateDraftRefund
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(command)
      @repository.with_aggregate(Refund, command.aggregate_id) do |refund|
        refund.create_draft(
          command.order_id,
          refundable_products(command.order_id)
          )
      end
    end

    private

    def refundable_products(order_id)
      RefundableProducts.new.call(@event_store, order_id)
    end
  end

  class OnAddItemToRefund
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Refund, command.aggregate_id) do |refund|
        refund.add_item(command.product_id)
      end
    end
  end

  class OnRemoveItemFromRefund
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Refund, command.aggregate_id) do |refund|
        refund.remove_item(command.product_id)
      end
    end
  end
end
