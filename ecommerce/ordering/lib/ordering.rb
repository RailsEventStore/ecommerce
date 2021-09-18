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
require_relative "ordering/service"
require_relative "ordering/order"

module Ordering
  class Configuration
    def initialize(number_generator)
      @number_generator = number_generator
    end

    def call(event_store, command_bus)
      cqrs = Infra::Cqrs.new(event_store, command_bus)

      cqrs.register(
        SubmitOrder,
        OnSubmitOrder.new(event_store, @number_generator.call)
      )
      cqrs.register(SetOrderAsExpired, OnSetOrderAsExpired.new(event_store))
      cqrs.register(MarkOrderAsPaid, OnMarkOrderAsPaid.new(event_store))
      cqrs.register(CancelOrder, OnCancelOrder.new(event_store))
    end
  end
end
