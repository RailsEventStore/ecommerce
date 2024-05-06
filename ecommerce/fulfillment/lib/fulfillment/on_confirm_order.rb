# frozen_string_literal: true

module Fulfillment
  class OnConfirmOrder
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.confirm
      end
    end
  end
end
