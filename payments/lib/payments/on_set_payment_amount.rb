module Payments
  class OnSetPaymentAmount
    include CommandHandler

    def call(command)
      repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
      stream = stream_name(Payment, command.order_id)
      payment = repository.load(Payment.new, stream)
      payment.set_amount(command.order_id, command.amount)
      repository.store(payment, stream)
    end
  end
end
