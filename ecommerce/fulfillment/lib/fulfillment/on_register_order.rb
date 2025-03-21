# frozen_string_literal: true

module Fulfillment
  class OnRegisterOrder
    def initialize(event_store, number_generator)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @number_generator = number_generator
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order_number = @number_generator.call
        order.register(order_number)
      end
    end
  end
end
