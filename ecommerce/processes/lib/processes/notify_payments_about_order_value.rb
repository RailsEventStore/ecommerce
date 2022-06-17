module Processes
  class NotifyPaymentsAboutOrderValue
    def initialize(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Payments::SetPaymentAmount.new(
              order_id: event.data.fetch(:order_id),
              amount: event.data.fetch(:discounted_amount).to_f
            )
          )
        end,
        [Pricing::OrderTotalValueCalculated]
      )
    end
  end
end