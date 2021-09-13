module Payments
  class OnAuthorizePayment
    def initialize
      @repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
      @gateway    = Rails.configuration.payment_gateway
    end

    def call(command)
      @repository.with_aggregate(Payment.new, "Payments::Payment$#{command.order_id}") do |payment|
        payment.authorize(command.order_id, @gateway.call)
      end
    end
  end
end
