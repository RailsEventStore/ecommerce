module Payments
  class OnCapturePayment
    include CommandHandler

    def call(command)
      payment = rehydrate(Payment.new, stream_name(Payment, command.transaction_id))
      payment.capture
      payment.store
    end
  end
end
