module Processes
  class NotifyPaymentsAboutOrderValue
    def initialize(event_store, command_bus)
      event_store.subscribe(
        ->(event) do
          command_bus.call(
            Payments::SetPaymentAmount.new(
              event.data.fetch(:order_id),
              event.data.fetch(:discounted_amount).to_f
            )
          )
        end,
        to: [Processes::TotalOrderValueUpdated]
      )
    end
  end
end
