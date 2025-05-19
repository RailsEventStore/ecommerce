module Processes
  class NotifyPaymentsAboutOrderValue
    def initialize(event_store, command_bus)
      event_store.subscribe(
        ->(event) do
          command_bus.call(
            Payments::SetPaymentAmount.new(
              order_id: event.data.fetch(:order_id),
              amount: event.data.fetch(:discounted_amount).to_f
            )
          )
        end,
        to: [Pricing::OrderTotalValueCalculated]
      )
    end
  end
end