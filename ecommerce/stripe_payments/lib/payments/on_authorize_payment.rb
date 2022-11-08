module Payments
  class OnAuthorizePayment
    def initialize(event_store)
      @repository = AggregateRoot::Repository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(
        Payment.new,
        "Payments::Payment$#{command.order_id}"
      ) { |payment| payment.authorize(command.payment_method_id) }
    end
  end
end
