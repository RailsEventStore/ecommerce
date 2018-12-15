module Payments
  class OnReleasePayment
    include CommandHandler

    def call(command)
      payment = rehydrate(Payment.new, stream_name(Payment, command.transaction_id))
      payment.release
      payment.store
    end
  end
end
