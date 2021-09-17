require_relative "../ordering"

module Ordering
  class Configuration
    def initialize(cqrs, event_store, number_generator)
      @cqrs = cqrs
      @event_store = event_store
      @number_generator = number_generator
    end

    def call
      @cqrs.register(SubmitOrder, OnSubmitOrder.new(@event_store, @number_generator.call))
      @cqrs.register(SetOrderAsExpired, OnSetOrderAsExpired.new(@event_store))
      @cqrs.register(MarkOrderAsPaid, OnMarkOrderAsPaid.new(@event_store))
      @cqrs.register(CancelOrder, OnCancelOrder.new(@event_store))
    end
  end
end