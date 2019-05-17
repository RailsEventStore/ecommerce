module Payments
  class OnCapturePayment
    include CommandHandler

    def call(command)
      repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
      stream = stream_name(Payment, command.transaction_id)
      payment = repository.load(Payment.new, stream)
      payment.capture
      repository.store(payment, stream)
    end
  end
end
