module Payments
  class OnAuthorizePayment
    include CommandHandler

    def call(command)
      repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
      stream = stream_name(Payment, command.transaction_id)
      payment = repository.load(Payment.new, stream)
      order = Orders::Order.find_by(uid: command.order_id)
      payment.authorize(command.transaction_id, command.order_id, Rails.configuration.payment_gateway.call, order.total_value)
      repository.store(payment, stream)
    end
  end
end
