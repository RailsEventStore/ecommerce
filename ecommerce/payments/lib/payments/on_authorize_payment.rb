module Payments
  class OnAuthorizePayment
    include Infra::CommandHandler

    def call(command)
      repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
      stream = stream_name(Payment, command.order_id)
      payment = repository.load(Payment.new, stream)
      payment.authorize(command.order_id, Rails.configuration.payment_gateway.call)
      repository.store(payment, stream)
    end
  end
end
