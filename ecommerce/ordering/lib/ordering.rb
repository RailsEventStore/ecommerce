require_relative "../../../infra/lib/infra"
require_relative "ordering/events/order_submitted"
require_relative "ordering/events/order_expired"
require_relative "ordering/events/order_paid"
require_relative "ordering/events/order_cancelled"
require_relative "ordering/commands/submit_order"
require_relative "ordering/commands/set_order_as_expired"
require_relative "ordering/commands/mark_order_as_paid"
require_relative "ordering/commands/cancel_order"
require_relative "ordering/fake_number_generator"
require_relative "ordering/number_generator"
require_relative "ordering/order"

module Ordering
  class OnCancelOrder
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.cancel
      end
    end
  end

  class OnMarkOrderAsPaid
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.confirm
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
      ActiveRecord::Base.transaction do
        @repository.with_aggregate(Order, command.aggregate_id) do |order|
          order_number = @number_generator.call
          order.submit(order_number, command.customer_id)
        end
      end
    end
  end
end



