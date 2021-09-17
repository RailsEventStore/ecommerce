module Payments
  class OnAuthorizePayment
    def initialize(event_store, gateway)
      @repository = AggregateRoot::Repository.new(event_store)
      @gateway = gateway
    end

    def call(command)
      @repository.with_aggregate(
        Payment.new,
        "Payments::Payment$#{command.order_id}"
      ) { |payment| payment.authorize(command.order_id, @gateway.call) }
    end
  end
end
