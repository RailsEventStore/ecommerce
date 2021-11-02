require "infra"
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
require_relative "ordering/service"
require_relative "ordering/order"

module Ordering
  class Configuration
    def initialize(number_generator)
      @number_generator = number_generator
    end

    def call(cqrs)
      cqrs.register_command(
        SubmitOrder,
        OnSubmitOrder.new(cqrs.event_store, @number_generator.call),
        OrderSubmitted
      )
      cqrs.register_command(SetOrderAsExpired, OnSetOrderAsExpired.new(cqrs.event_store), OrderExpired)
      cqrs.register_command(MarkOrderAsPaid, OnMarkOrderAsPaid.new(cqrs.event_store), OrderPaid)
      cqrs.register_command(CancelOrder, OnCancelOrder.new(cqrs.event_store), OrderCancelled)
    end
  end
end
