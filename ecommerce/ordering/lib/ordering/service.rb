module Ordering
  class OnAddItemToBasket
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.add_item(command.product_id)
      end
    end
  end

  class OnRemoveItemFromBasket
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.remove_item(command.product_id)
      end
    end
  end

  class OnSetOrderAsExpired
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.expire
      end
    end
  end

  class OnSubmitOrder
    def initialize(event_store, number_generator)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @number_generator = number_generator
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order_number = @number_generator.call
        order.submit(order_number)
      end
    end
  end

  class OnAcceptOrder
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.accept
      end
    end
  end

  class OnRejectOrder
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.reject
      end
    end
  end

  class OnCreateDraftRefund
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Refund, command.aggregate_id) do |refund|
        refund.create_draft(command.order_id)
      end
    end
  end

  class OnAddItemToRefund
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(command)
      @repository.with_aggregate(Refund, command.aggregate_id) do |refund|
        refund.add_item(
          command.product_id,
          available_quantity_to_refund(command.order_id, command.product_id)
        )
      end
    end

    private

    def available_quantity_to_refund(order_id, product_id)
      Projections
        .product_quantity_available_to_refund(order_id, product_id)
        .run(@event_store)
        .fetch(:available)
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
