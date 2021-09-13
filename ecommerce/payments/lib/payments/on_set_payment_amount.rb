module Payments
  class OnSetPaymentAmount
    def initialize
      @repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
    end

    def call(command)
      @repository.with_aggregate(Payment.new, "Payments::Payment$#{command.order_id}") do |payment|
        payment.set_amount(command.order_id, command.amount)
      end
    end
  end
end
