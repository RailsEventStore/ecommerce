module Ordering
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register(SubmitOrder, OnSubmitOrder.new(number_generator: Rails.configuration.number_generator.call))
      @cqrs.register(SetOrderAsExpired, OnSetOrderAsExpired.new)
      @cqrs.register(MarkOrderAsPaid, OnMarkOrderAsPaid.new)
      @cqrs.register(CancelOrder, OnCancelOrder.new)
    end
  end
end