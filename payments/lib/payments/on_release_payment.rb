module Payments
  class OnReleasePayment
    include CommandHandler

    def call(command)
      repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
      stream = stream_name(Payment, command.transaction_id)
      payment = repository.load(Payment.new, stream)
      payment.release
      repository.store(payment, stream)
    end
  end
end
