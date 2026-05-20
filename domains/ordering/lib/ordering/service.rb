module Ordering
  class OnCreateDraftReturn
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Return, command.aggregate_id) do |return_order|
        return_order.create_draft(command.order_id, command.returnable_products)
      end
    end
  end

  class OnAddItemToReturn
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Return, command.aggregate_id) do |return_order|
        return_order.add_item(command.product_id)
      end
    end
  end

  class OnRemoveItemFromReturn
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Return, command.aggregate_id) do |return_order|
        return_order.remove_item(command.product_id)
      end
    end
  end

  OnCreateDraftRefund = OnCreateDraftReturn
  OnAddItemToRefund = OnAddItemToReturn
  OnRemoveItemFromRefund = OnRemoveItemFromReturn
end
